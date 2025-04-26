#!/bin/bash

sleep 0.5

# Create .todo directory
echo "📁 Creating your productivity hub..."
sleep 0.5
mkdir -p ~/.todo
sleep 0.5
echo "  ✅ Created: ~/.todo/"

sleep 0.5

if [ -f "todo.sh" ]; then
  mv todo.sh ~/.todo/
  chmod +x ~/.todo/todo_tui.sh
  sleep 0.5
  echo "  🚀 Installed todo.sh to ~/.todo/"
else
  echo "❌ Error: Couldn't find todo.sh in current directory!" >&2
  exit 1
fi
if [ -f "todocli.sh" ]; then
  mv todocli.sh ~/.todo/
  chmod +x ~/.todo/todo_cli.sh
  sleep 0.5
  echo "  🚀 Installed todocli.sh to ~/.todo/"
else
  echo "❌ Error: Couldn't find todocli.sh in current directory!" >&2
  exit 1
fi

add_alias() {
  local file=$1
  if [ -f "$file" ]; then
    if ! grep -q "alias todo=" "$file"; then
      echo -e "\n# Todo Manager Alias" >> "$file"
      echo "alias todo='~/.todo/todo.sh'" >> "$file"
      echo "alias todocli='~/.todo/todocli.sh'" >> "$file"
      echo "  ✨ Added alias to $file"
    else
      echo "  ⏩ Alias already exists in $file"
    fi
  fi
}

echo "🔧 Setting up shortcuts..."
add_alias ~/.bashrc
add_alias ~/.zshrc

sleep 0.5

echo -e "\n🎉 All set! Now you can:"
sleep 0.2
echo " Restart your terminal and type todo for 'TUI' and todocli for 'CLI' "

