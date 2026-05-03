use std::sync::Arc;

use anyhow::{Context, Result};
use clap::{Parser, Subcommand};
use hooq::hooq;
use reqwest::Client;
use serde::Deserialize;

#[derive(Parser, Debug)]
#[command(name = "my-cli", version, about = "Example async Rust CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand, Debug)]
enum Commands {
    Fetch {
        #[arg(long)]
        url: String,

        #[arg(long, env = "MY_CLI_TOKEN")]
        token: Option<String>,
    },
}

#[derive(Debug, Deserialize)]
struct ApiResponse {
    #[allow(dead_code)]
    ok: bool,
}

#[derive(thiserror::Error, Debug)]
enum FetchError {
    #[error("HTTP request failed")]
    Http(#[from] reqwest::Error),
    #[error("invalid JSON response")]
    Json(#[from] serde_json::Error),
}

#[tokio::main]
#[hooq(anyhow)]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();

    let cli = Cli::parse();
    let client = Arc::new(Client::new());

    match cli.command {
        Commands::Fetch { url, token } => fetch(client, &url, token.as_deref()).await?,
    }

    Ok(())
}

#[hooq(anyhow)]
async fn fetch(client: Arc<Client>, url: &str, token: Option<&str>) -> Result<()> {
    let mut req = client.get(url);
    if let Some(t) = token {
        req = req.bearer_auth(t);
    }

    let body = req
        .send()
        .await
        .map_err(FetchError::from)
        .with_context(|| format!("requesting {url}"))?
        .text()
        .await
        .map_err(FetchError::from)?;

    let parsed: ApiResponse = serde_json::from_str(&body)
        .map_err(FetchError::from)
        .with_context(|| "parsing response body")?;

    println!("{:?}", parsed);
    Ok(())
}
