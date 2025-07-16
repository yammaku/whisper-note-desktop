#!/usr/bin/osascript

on run argv
    if (count of argv) < 2 then
        return "Usage: osascript append_to_note.applescript \"Note Title\" \"Text to append\""
    end if
    
    set noteTitle to item 1 of argv
    set textToAppend to item 2 of argv
    
    tell application "Notes"
        try
            -- Find the note with the specified title
            set targetNote to first note whose name is noteTitle
            
            -- Get the current body of the note
            set currentBody to body of targetNote
            
            -- Append the new text with a line break
            -- Apple Notes will handle the HTML formatting internally
            set body of targetNote to currentBody & "<br><br>" & textToAppend
            
            return "Successfully appended text to note: " & noteTitle
        on error errMsg
            return "Error: " & errMsg
        end try
    end tell
end run