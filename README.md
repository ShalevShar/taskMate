<div align="center">
    <h1>TaskMate App</h1>
    <p>A smart and collaborative task management app designed to help you stay organized and work efficiently with others.</p>
</div>

---

<div align="center">
    <h3>Core Features</h3>
    <p><b>Task Records</b><br>
    Create and manage task records, each containing a list of items that can be checked off as completed.</p>
</div>

<div align="center">
    <img width="200" alt="task-records" src="https://github.com/user-attachments/assets/task-records.png">
</div>

<div align="center">
    <p><b>Collaborative Work</b><br>
    Share and collaborate on task records with others to work together more effectively.</p>
</div>

<div align="center">
    <img width="201" alt="collaboration" src="https://github.com/user-attachments/assets/collaboration.png">
</div>

<div align="center">
    <p><b>Manage Items and Records</b><br>
    Easily add, check off, and delete individual items within records. You can also remove entire records when they are no longer needed.</p>
</div>

<div align="center">
    <img width="200" alt="ScreenRecording2024-08-26at21" src="https://github.com/user-attachments/assets/54164609-c028-4a24-b4fd-d5fb086746a9">
     
</div>

---

# Usage
### XML Layout Example:
```xml
<com.example.taskmate.TaskView
    android:id="@+id/taskView"
    android:layout_width="match_parent"
    android:layout_height="wrap_content"
    app:theme="dark"
    app:collaborationEnabled="true" />
