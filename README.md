
# 🌟 TODO CLI and TUI BOTH 🌟  
### TUI PREVIEW
![](/todo_cli.png)

### CLI PREVIEW

https://github.com/user-attachments/assets/bd8a1f4e-aa81-4995-9631-d1ad5ffe8e40



---

## 🚀 Features    
- **Both TUI and CLI Feature**: use whatever version you like
- **Task Lists**: Track daily 🌞, weekly 📅, and monthly 🌙 tasks.  
- **Progress Bars**: Watch bars fill up as you complete tasks!   
- **Earn Stars**: Complete tasks → collect ⭐ (1 per task)!
- **Score Board**: Track lifetime achievements and shows the **( total tasks completed/total tasks added  )** in reward window .
- **Daily/Weekly/Monthly Goals**: Reset automatically at midnight 🕛, Monday 🌅, and month-end 🌌.    
- **Build Streaks**: Finish *all* daily tasks → streak +1!  **(UPDATE AT 12AM MIDNIGHT EVERYDAY)**
- **Weekly Stars**: Collect 7 stars/week → unlock a "Streak Boost" 🚀.  
- **Fail-Safe**: Miss a day? Streak resets to 0 😢.  
- **Notes**: Save text 📄 or links 🔗 
- **Edit Notes**: Delete or edit notes📄 anytime.
- **Countdowns**: Supports adding multiple countdown windows⏳ with **Countdown labels**.  
- **Remove Tasks**: Changed your mind? Delete tasks easily 🗑️.

## 💡Tips
- Delete tasks you won't do → keeps stats accurate 🎯 else streak will reset. removed tasks doesn't counts.
##  🔵 TUI USAGES
### Adding multiple tasks 📜
use ```|``` between tasks to add multiple tasks at once spacing doesn't matter.

Example ```Gym|Call Mom | Do Maths | Do Physics|Do Chemistry```
## Result 
       1.Gym
       2.Call Mom
       3.Do Math
       4.DO Physics
       5.Do Chemistry
---
##  🔴 CLI USAGES
# Run 
```
todocli --help
```
## Usage:
```
todocli [command] [options]
```
## 📌 Basic Commands:
 - todocli --help&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Show this help message

## 📝 Task Operations:
 - todocli add task --period [day/week/month] --tasks "Task1|Task2"
 - todocli remove task --period [day/week/month] --task "Task Name"
 - todocli complete task --period [day/week/month] --task "Task Name"

## 📚 Note Operations:
 - todocli add note --type [text/link] --content "Content"
 - todocli edit note 
 - todocli delete note 

## 🎯 Target Dates:
 - todocli set-target "Label" "YYYY-MM-DD"
 - todocli remove target date    

## 🔍 Show Commands:
 - todocli show day task          
 - todocli show week task         
 - todocli show month task        
 - todocli show all tasks         
 - todocli show notes           
 - todocli show streak            
 - todocli show target dates    

## 🔍 Examples:
 - todocli add task --period day --tasks "Gym|Math homework"
 - todocli complete task --period day --task "Gym"
 - todocli show week task
 - todocli set-target "Exam" "2023-12-15"
 
---

### 🛠️ **Setup**  
  Install dependencies:  
   ```bash  
   brew install gum jq bc bsdmainutils  # macOS
   ``` 
   # For Linux:
   ```
   sudo apt-get install gum jq bc bsdmainutils # ubuntu/debian
   ```
   ```
   sudo pacman -S util-linux gum jq bc # Arch based system
   ```

### 🛠️ Full-Setup
   1. Clone this repository
   ```
    git clone https://github.com/Harsh-bin/TODO-CLI-and-TUI.git  
   ```
   ```
    cd TODO-CLI-and-TUI
   ```
   ```
    chmod +x ./install.sh
   ```
   ```
    ./install.sh
   ```
   2. Restart terminal and run
   ```
     todo # TUI MODE
   ```
   ```
     todocli [command] [options] # CLI MODE
   ```
  3. Everything done NOW enjoy✌️
### Uninstalling todo app
   ```
   chmod +x ./uninstall.sh
   ```
   ```
   ./uninstall.sh
   ```
