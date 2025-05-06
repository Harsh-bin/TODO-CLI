#!/bin/bash

sleep 0.5
echo "📁 Creating your productivity hub..."
sleep 0.5
mkdir -p ~/.todo
sleep 0.5
echo "  ✅ Created: ~/.todo/"
sleep 0.5
if [ -f "todo_tui.sh" ]; then
  cp todo_tui.sh ~/.todo/
  chmod +x ~/.todo/todo_tui.sh
  sleep 0.5
  echo "  🚀 Installed todo_tui.sh to ~/.todo/"
else
  echo "❌ Error: Couldn't find todo_tui.sh in current directory!" >&2
  exit 1
fi
if [ -f "todo_cli.sh" ]; then
  cp todo_cli.sh ~/.todo/
  chmod +x ~/.todo/todo_cli.sh
  sleep 0.5
  echo "  🚀 Installed todo_cli.sh to ~/.todo/"
else
  echo "❌ Error: Couldn't find todo_cli.sh in current directory!" >&2
  exit 1
fi

add_alias() {
  local file=$1
  if [ -f "$file" ]; then
    if ! grep -q "alias todo=" "$file"; then
      echo -e "\n# Todo Manager Alias" >> "$file"
      echo "alias todo='~/.todo/todo_tui.sh'" >> "$file"
      echo "alias todocli='~/.todo/todo_cli.sh'" >> "$file"
      echo "  ✨ Added alias to $file"
    else
      echo "  ⏩ Alias already exists in $file"
    fi
  fi
}

echo "🔧 Setting up shortcuts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  add_alias ~/.bash_profile  
  add_alias ~/.bashrc       
else
  add_alias ~/.bashrc        
fi
add_alias ~/.zshrc   
sleep 0.5
echo -e "\n🎉 All set! Now you can:"
sleep 0.2
echo " Restart your terminal and type todo for 'TUI' and todocli for 'CLI' "

