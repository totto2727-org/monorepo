use std::time::Duration;

use iocraft::prelude::*;

const FRAMES: [&str; 10] = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

#[derive(Default, Props)]
pub struct SpinnerProps {
    pub label: String,
    pub done: bool,
}

#[component]
pub fn Spinner(props: &SpinnerProps, mut hooks: Hooks) -> impl Into<AnyElement<'static>> {
    let mut frame = hooks.use_state(|| 0usize);
    let label = props.label.clone();
    let done = props.done;

    hooks.use_future(async move {
        loop {
            tokio::time::sleep(Duration::from_millis(80)).await;
            frame.set((frame.get() + 1) % FRAMES.len());
        }
    });

    let icon = if done {
        "✔".to_string()
    } else {
        FRAMES[frame.get()].to_string()
    };
    let color = if done { Color::Green } else { Color::Cyan };

    element! {
        View {
            Text(color: color, content: icon)
            Text(content: format!(" {}", label))
        }
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    element!(Spinner(label: "Loading...".to_string(), done: false))
        .render_loop()
        .await?;
    Ok(())
}
