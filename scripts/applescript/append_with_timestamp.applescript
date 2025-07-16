#!/usr/bin/osascript

on run argv
    if (count of argv) < 2 then
        return "Usage: osascript append_with_timestamp.applescript \"Note Title\" \"Text to append\""
    end if
    
    set noteTitle to item 1 of argv
    set textToAppend to item 2 of argv
    
    -- Get current date and time
    set currentDate to current date
    set timeString to time string of currentDate
    set dateString to short date string of currentDate
    
    tell application "Notes"
        try
            -- Find the note with the specified title
            set targetNote to first note whose name is noteTitle
            
            -- Get the current body of the note
            set currentBody to body of targetNote
            
            -- Create formatted append with timestamp
            set formattedAppend to "<br><br><b>[" & dateString & " " & timeString & "]</b><br>" & textToAppend
            
            -- Append the new text with formatting
            set body of targetNote to currentBody & formattedAppend
            
            return "Successfully appended text with timestamp to note: " & noteTitle
        on error errMsg
            -- If note doesn't exist, offer to create it
            if errMsg contains "Can't get note" then
                return "Note '" & noteTitle & "' not found. Please create it first or check the title."
            else
                return "Error: " & errMsg
            end if
        end try
    end tell
end run