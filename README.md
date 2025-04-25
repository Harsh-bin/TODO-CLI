
# 🌟 TODO-CLI 🌟  
![](/todo_cli.png)

---

## 🚀 Features    
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
# How TO Use
  simply download the todo.sh file from release and run

   ```
   ./todo.sh
   ```
### Full-Setup
   1. Clone this repository
   ```
    git clone https://github.com/Harsh-bin/TODO-CLI.git
   ```
   ```
    cd TODO-CLI
   ```
   ```
    chmod +x ./install.sh
   ```
   ```
    ./install.sh
   ```
   2. Restart terminal and run
   ```
     todo
   ```
  3. Everything done NOW enjoy✌️
### Uninstalling todo app
   ```
   chmod +x ./uninstall.sh
   ```
   ```
   ./uninstall.sh
   ```
