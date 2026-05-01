
const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, 'data');
const inputFile = path.join(dataDir, 'election_candidates.json');
const outputDir = path.join(dataDir, 'candidates_split');

// Ensure output directory exists
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// Read the large JSON file
fs.readFile(inputFile, 'utf8', (err, data) => {
  if (err) {
    console.error('Error reading the file:', err);
    return;
  }

  try {
    const candidates = JSON.parse(data);
    const chunkSize = 1000;
    let fileIndex = 0;

    for (let i = 0; i < candidates.length; i += chunkSize) {
      const chunk = candidates.slice(i, i + chunkSize);
      const outputFile = path.join(outputDir, `candidates_${fileIndex}.json`);
      fs.writeFileSync(outputFile, JSON.stringify(chunk, null, 2));
      console.log(`Created ${outputFile}`);
      fileIndex++;
    }

    console.log(`Successfully split the file into ${fileIndex} parts.`);
  } catch (parseErr) {
    console.error('Error parsing JSON:', parseErr);
  }
});