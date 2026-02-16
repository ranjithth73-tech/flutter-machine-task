import subprocess
import datetime
import os

# Original commit hashes in reverse order (oldest first)
commits = [
    "41c256be68c4e6fd0ef4312e3577cab0abf6af9d",
    "564131a51a364f669397c1199bc88ab2f10b74ed",
    "87b3824ae9d304ed07f13255b2ab3a45bf63f707",
    "9e35b032cc990f4a78895362873f9c5a18e633fc",
    "1ade9523bdacc707ed4f8e1fde206c00050633e5",
    "b7a3467fea35994f7f04574e5c599049793a50b2",
    "4402f5fd07854adea1b42e54bd5d92bd875834cb"
]

# Base date: Today at 15:00
base_time = datetime.datetime.now().replace(hour=15, minute=0, second=0, microsecond=0)

# Create orphan branch
subprocess.run(["git", "checkout", "--orphan", "spaced_commits"], check=True)
subprocess.run(["git", "rm", "-rf", "."], check=True)

try:
    for i, commit_hash in enumerate(commits):
        # Calculate new time
        new_time = base_time + datetime.timedelta(minutes=18 * i)
        date_str = new_time.strftime("%Y-%m-%dT%H:%M:%S%z") # Format with timezone if needed, or simple ISO

        # Cherry-pick the commit
        print(f"Applying commit {commit_hash} at {date_str}")
        result = subprocess.run(["git", "cherry-pick", commit_hash], capture_output=True, text=True)
        
        # If conflict or empty commit, handle it (though unlikely with cherry-pick)
        if result.returncode != 0:
            print(f"Error picking {commit_hash}: {result.stderr}")
            # If empty commit (no changes), allow proceeding
            if "nothing to commit" in result.stderr:
                 subprocess.run(["git", "commit", "--allow-empty", "--amend", "--no-edit", f"--date={date_str}"], check=True)
            else:
                 raise Exception("Cherry-pick failed")
        
        # Amend date
        subprocess.run(["git", "commit", "--amend", "--no-edit", f"--date={date_str}"], check=True)
        
        # Sleep slightly to avoid identical seconds? Not needed if using explicit date.

    print("History rewritten successfully on branch 'spaced_commits'")
    
    # Add new remote
    subprocess.run(["git", "remote", "remove", "origin"], check=False) # remove old if exists
    subprocess.run(["git", "remote", "add", "origin", "https://github.com/ranjithth73-tech/flutter-machine-task.git"], check=True)
    
except Exception as e:
    print(f"Script failed: {e}")
