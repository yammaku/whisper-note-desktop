#!/usr/bin/env node

const { exec } = require('child_process');
const { promisify } = require('util');
const path = require('path');
const execAsync = promisify(exec);

class NotesAppender {
  async appendToNote(noteTitle, textToAppend, includeTimestamp = false) {
    try {
      // Escape special characters for AppleScript
      const escapedTitle = noteTitle.replace(/"/g, '\\"');
      const escapedText = textToAppend.replace(/"/g, '\\"').replace(/\n/g, '<br>');
      
      // Choose which script to use
      const scriptName = includeTimestamp ? 'append_with_timestamp.applescript' : 'append_to_note.applescript';
      const scriptPath = path.join(__dirname, scriptName);
      
      // Execute the AppleScript
      const command = `osascript "${scriptPath}" "${escapedTitle}" "${escapedText}"`;
      const { stdout, stderr } = await execAsync(command);
      
      if (stderr) {
        console.error('AppleScript error:', stderr);
        return { success: false, error: stderr };
      }
      
      console.log(stdout.trim());
      return { success: true, message: stdout.trim() };
    } catch (error) {
      console.error('Error appending to note:', error.message);
      return { success: false, error: error.message };
    }
  }
}

async function main() {
  const args = process.argv.slice(2);
  
  if (args.length < 2) {
    console.log(`
Apple Notes Append Tool

Usage:
  node append_to_note.js <note-title> <text-to-append> [--timestamp]

Examples:
  node append_to_note.js "Jul 16, 2025" "New text to add"
  node append_to_note.js "Jul 16, 2025" "Text with timestamp" --timestamp

Options:
  --timestamp    Include date/time stamp before the appended text
    `);
    process.exit(1);
  }
  
  const noteTitle = args[0];
  const textToAppend = args[1];
  const includeTimestamp = args.includes('--timestamp');
  
  const appender = new NotesAppender();
  await appender.appendToNote(noteTitle, textToAppend, includeTimestamp);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = NotesAppender;