const fs = require('fs');
const pdfParse = require('pdf-parse');

async function extractPDF(filePath, outputPath, maxPages = 50) {
    try {
        console.log(`Processing: ${filePath}`);
        const dataBuffer = fs.readFileSync(filePath);
        const data = await pdfParse(dataBuffer, { max: maxPages });
        
        const output = `PDF: ${filePath}
Pages: ${data.numpages}
Text Length: ${data.text.length} characters

--- CONTENT ---

${data.text.substring(0, 50000)}

${data.text.length > 50000 ? '\n... [truncated, full text available in file] ...' : ''}
`;
        
        fs.writeFileSync(outputPath, output);
        console.log(`✅ Extracted to: ${outputPath}`);
        console.log(`Pages: ${data.numpages}, Chars: ${data.text.length}`);
        return data;
    } catch (err) {
        console.error(`❌ Error processing ${filePath}:`, err.message);
        return null;
    }
}

async function main() {
    const files = [
        {
            pdf: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\1 - Biodesign_ The Process of Innovating Medical Technologies-Cambridge University Press (2015).pdf",
            txt: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\biodesign-extracted.txt",
            desc: "Biodesign - Medical Technology Innovation Process"
        },
        {
            pdf: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\Atlas of emergency neurosurgery -- Raksin, Raksin Patricia B_; Ullman, Jamie -- Thieme Medical Pub.pdf",
            txt: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\atlas-emergency-neurosurgery-extracted.txt",
            desc: "Atlas of Emergency Neurosurgery"
        },
        {
            pdf: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\Handbook of Bleeding and Coagulation for Neurosurgery (2015, Thieme) .pdf",
            txt: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\handbook-bleeding-coagulation-extracted.txt",
            desc: "Handbook of Bleeding and Coagulation for Neurosurgery"
        },
        {
            pdf: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\Mark S. Greenberg - Handbook of Neurosurgery (2020.pdf",
            txt: "C:\\Users\\impro\\Documents\\Reading\\Neuro\\handbook-neurosurgery-greenberg-extracted.txt",
            desc: "Handbook of Neurosurgery (Greenberg)"
        }
    ];
    
    console.log('=== NEUROVASCULAR PDF EXTRACTION ===\n');
    
    for (const file of files) {
        console.log(`\n📖 ${file.desc}`);
        await extractPDF(file.pdf, file.txt, 100); // Extract first 100 pages
    }
    
    console.log('\n=== EXTRACTION COMPLETE ===');
    console.log('Files saved to C:\\Users\\impro\\Documents\\Reading\\Neuro\\');
}

main().catch(console.error);
