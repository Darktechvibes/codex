// NoteMaster3001 v1.0 - clipboard based note manager for Scriptable
// Stores text and image notes in iCloud.

/* --- CONFIG --------------------------------------------------- */
const MAX_ITEMS = 100;           // max number of notes
const MAX_BYTES = 500_000;       // overall JSON size limit
const JPEG_QUALITY = 0.8;        // compression for images

/* --- FILE SETUP ------------------------------------------------ */
const FM   = FileManager.iCloud();
const DIR  = FM.documentsDirectory();
const PATH = FM.joinPath(DIR, "noteStore.json");

/* --- UTILITIES ------------------------------------------------- */
function ensureFile() {
  if (!FM.fileExists(PATH)) FM.writeString(PATH, "[]");
}

async function loadNotes() {
  ensureFile();
  return JSON.parse(FM.readString(PATH));
}

async function saveNotes(arr) {
  let trimmed = arr.slice(-MAX_ITEMS);
  while (Data.fromString(JSON.stringify(trimmed)).length >= MAX_BYTES) {
    trimmed.shift();
  }
  await FM.writeString(PATH, JSON.stringify(trimmed));
}

async function pushNote(val, type) {
  if (!val) return;
  const notes = await loadNotes();
  const last = notes[notes.length - 1];
  if (last && last.type === type && last.val === val) return;
  notes.push({ ts: new Date().toISOString(), type, val });
  await saveNotes(notes);
}

async function pushImage(img) {
  const data = img.jpegData(JPEG_QUALITY);
  await pushNote(data.toBase64String(), "image");
}

/* --- MENU ------------------------------------------------------ */
async function main() {
  const curStr = Pasteboard.pasteString();
  const curImg = Pasteboard.pasteImage();

  let menu = new Alert();
  menu.title = "NoteMaster3001";
  menu.message = curStr ?? (curImg ? "[\uD83D\uDDBC obrázek]" : "[prázdno]");
  menu.addAction("\u2795 Z clipboardu");
  menu.addAction("\u270F Nová poznámka");
  menu.addAction("\uD83D\uDCDD Show Notes");
  menu.addAction("\u274C Delete Note");
  menu.addAction("\uD83D\uDCE4 Export JSON");
  menu.addAction("🗑 Clear All");
  menu.addCancelAction("Zrušit");
  const choice = await menu.presentAlert();

  switch (choice) {
    // Add from clipboard
    case 0: {
      if (curImg) await pushImage(curImg);
      else await pushNote(curStr, "string");
      break;
    }
    // Add typed note
    case 1: {
      let a = new Alert();
      a.title = "Nová poznámka";
      a.addTextField("Text", "");
      a.addAction("Uložit");
      a.addCancelAction("Zrušit");
      const idx = await a.presentAlert();
      if (idx !== -1) {
        const text = a.textFieldValue(0);
        await pushNote(text, "string");
      }
      break;
    }
    // Show notes
    case 2: {
      const notes = await loadNotes();
      let table = new UITable();
      notes.slice().reverse().forEach((n, i) => {
        let row = new UITableRow();
        let t = new Date(n.ts).toLocaleString();
        let p = n.type === "image" ? "[\uD83D\uDDBC]" : (n.val.slice?.(0,30) || n.val);
        row.addText(t, p);
        table.addRow(row);
      });
      await table.present();
      break;
    }
    // Delete note
    case 3: {
      const notes = await loadNotes();
      if (!notes.length) break;
      let table = new UITable();
      notes.map((n, idx) => {
        let row = new UITableRow();
        let p = n.type === "image" ? "[\uD83D\uDDBC]" : (n.val.slice?.(0,30) || n.val);
        row.addText(idx + 1 + ". ", p);
        row.onSelect = async () => {
          notes.splice(idx,1);
          await saveNotes(notes);
          table.removeRow(idx);
          table.reload();
        };
        table.addRow(row);
      });
      await table.present();
      break;
    }
    // Export JSON
    case 4: {
      const notes = await loadNotes();
      const data = Data.fromString(JSON.stringify(notes, null, 2));
      await QuickLook.present(data);
      break;
    }
    // Clear all
    case 5: {
      let confirm = new Alert();
      confirm.title = "Smazat vše?";
      confirm.addAction("Ano");
      confirm.addCancelAction("Ne");
      const ok = await confirm.presentAlert();
      if (ok === 0) await saveNotes([]);
      break;
    }
    default:
      break;
  }
  Script.complete();
}

main();

