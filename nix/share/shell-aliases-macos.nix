{
  rm = ''
    echo 'use "trash" commands' >&2; false
  '';
  kanata = "sudo kanata -c $HOME/.config/kanata/kanata.kbd";
  karabiner = "sudo '/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon'";
}
