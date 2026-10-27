import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const dir=path.dirname(fileURLToPath(import.meta.url));
let html=await readFile(path.join(dir,'template.html'),'utf8');
const css=await readFile(path.join(dir,'style.css'),'utf8');
const dungeon=(await readFile(path.join(dir,'dungeon.js'),'utf8')).replace(/^export /gm,'');
const ai=(await readFile(path.join(dir,'ai.js'),'utf8')).replace(/^import .* from '\.\/dungeon\.js';\s*/gm,'').replace(/^export /gm,'');
const audioPath=path.join(dir,'assets/music/Nineteen_Steps_loop.mp3');
const musicData=(await readFile(audioPath)).toString('base64');
const audio=(await readFile(path.join(dir,'audio.js'),'utf8'))
  .replace(/^export /gm,'')
  .replace("const TRACK_URL='assets/music/Nineteen_Steps_loop.mp3';",`const TRACK_URL='data:audio/mpeg;base64,${musicData}';`);
const game=(await readFile(path.join(dir,'game.js'),'utf8'))
  .replace(/^import .* from '\.\/(?:dungeon|ai|audio)\.js';\s*/gm,'');
const source=`${dungeon}\n${ai}\n${audio}\n${game}`;
html=html.replace(/\s*<link rel="manifest"[^>]+>/,'').replace(/\s*<link rel="icon"[^>]+>/,'');
html=html.replace('<link rel="stylesheet" href="style.css">',`<style>\n${css}\n</style>`);
html=html.replace('<script type="module" src="game.js"></script>',`<script type="module">\n${source}\n</script>`);
const out=path.join(dir,'../index.html');await writeFile(out,html);
console.log(`Built fully self-contained offline game with Nineteen Steps: ${out} (${(Buffer.byteLength(html)/1024/1024).toFixed(2)} MiB)`);
