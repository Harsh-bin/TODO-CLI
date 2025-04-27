#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

sleep 0.5

echo -e "${YELLOW}🗑️ Starting Todo Manager Uninstaller${NC}"

sleep 0.5
if [ -d ~/.todo ]; then
    rm -rf ~/.todo
    echo -e "${GREEN}✅ Deleted: ~/.todo directory${NC}"
else
    echo -e "ℹ️ ~/.todo directory not found"
fi
sleep 0.5

remove_alias() {
    local file=$1
    if [ -f "$file" ]; then
        if grep -q "alias todo=" "$file" || grep -q "alias todocli=" "$file"; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/^# Todo Manager Alias$/,/^alias todocli=.*$/d' "$file"
            else
                sed -i '/^# Todo Manager Alias$/,/^alias todocli=.*$/d' "$file"
            fi
            echo -e "${GREEN}✅ Removed todo aliases from: $file${NC}"
        else
            echo -e "ℹ️ No todo aliases found in: $file"
        fi
    fi
}

sleep 0.5
echo -e "\n🔧 Cleaning up shell configurations..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    remove_alias ~/.bash_profile
    remove_alias ~/.bashrc  
else
    remove_alias ~/.bashrc  
fi
remove_alias ~/.zshrc

sleep 0.5
if [ -d ~/.cache/todo ]; then
    rm -rf ~/.cache/todo
    echo -e "${GREEN}✅ Deleted cache files${NC}"
fi
sleep 0.5
echo -e "\n${YELLOW}⚠️ Note:${NC}"
sleep 0.2
echo -e "1. Close and reopen all terminal windows to complete cleanup"
sleep 0.3
echo -e "2. Your task data in ~/.todo_config/ was ${RED}not removed${NC} (keep your history)"
sleep 0.3
echo -e "   Run ${YELLOW}rm -rf ~/.todo_config${NC} if you want to delete all task data"
sleep 0.3
echo -e "\n${GREEN}🎉 Uninstall complete! Thanks for trying Todo Manager.${NC}"
