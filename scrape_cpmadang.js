const axios = require('axios');
const cheerio = require('cheerio');
const fs = require('fs');

const BASE_URL = 'https://cpmadang.org/people/list_of_candidates_2026';
const CANDIDATES_FILE_PATH = '/Users/jtsgrit0/Documents/flutter/elecko26/data/election_candidates.json';
const START_PAGE = process.argv[2] ? parseInt(process.argv[2]) : 0;
const END_PAGE = process.argv[3] ? parseInt(process.argv[3]) : 238;

async function scrapeAndMergeCandidates() {
    let existingCandidates = [];
    if (fs.existsSync(CANDIDATES_FILE_PATH)) {
        const fileContent = fs.readFileSync(CANDIDATES_FILE_PATH, 'utf-8');
        existingCandidates = JSON.parse(fileContent);
    }

    for (let page = START_PAGE; page <= END_PAGE; page++) {
        console.log(`Scraping page ${page} of ${END_PAGE}...`);
        try {
            const { data: htmlContent } = await axios.get(`${BASE_URL}?page=${page}`);
            const $ = cheerio.load(htmlContent);

            $('.candidate-card').each((index, element) => {
                const party = $(element).find('.info-party a').text().trim();
                const nameWithHanzi = $(element).find('.info-name a').text().trim();
                const name = nameWithHanzi.split('(')[0].trim();
                const district = $(element).find('.info-meta-line .meta-item a').first().text().trim();
                const imageUrlRelative = $(element).find('.candidate-face img').attr('src');
                const imageUrl = imageUrlRelative ? `https://cpmadang.org${imageUrlRelative}` : "";
                const school = $(element).find('.flow-part.school').text().trim();
                const career = $(element).find('.flow-part.career').text().trim();
                const bio = [school, career].filter(Boolean).join(' ');

                if (!name || name.length < 2) {
                    return; // Skip if name is invalid
                }

                const existingCandidateIndex = existingCandidates.findIndex(c => c.name === name && c.party === party);

                if (existingCandidateIndex !== -1) {
                    // Update existing candidate
                    const cand = existingCandidates[existingCandidateIndex];
                    cand.district = district || cand.district;
                    cand.imageUrl = imageUrl || cand.imageUrl;
                    cand.bio = bio || cand.bio;
                    if (bio) {
                        cand.achievementsList = [bio];
                    }
                    console.log(`Updated candidate: ${name}`);
                } else {
                    // Add new candidate
                    const newCandidate = {
                        id: `member_${name.toLowerCase().replace(/\s/g, '')}_${Date.now()}`,
                        name: name,
                        party: party,
                        district: district,
                        imageUrl: imageUrl,
                        bio: bio,
                        electionDate: "2026-06-03T00:00:00.000",
                        term: 0,
                        achievementsList: bio ? [bio] : [],
                        actions: [],
                        policies: [],
                        pressReports: [],
                        sourceUrl: "",
                        crawledDate: new Date().toISOString(),
                        confidence: 0.7, // Higher confidence as it's from a trusted source
                        rawText: "",
                        analysis: "cpmadang.org에서 새로 추가된 후보자입니다."
                    };
                    existingCandidates.push(newCandidate);
                    console.log(`Added new candidate: ${name}`);
                }
            });

        } catch (error) {
            console.error(`Error scraping page ${page}:`, error.message);
        }
        // Delay to avoid overwhelming the server
        await new Promise(resolve => setTimeout(resolve, 500));
    }

    fs.writeFileSync(CANDIDATES_FILE_PATH, JSON.stringify(existingCandidates, null, 2));
    console.log(`Finished scraping pages from ${START_PAGE} to ${END_PAGE}. election_candidates.json has been updated.`);
}

scrapeAndMergeCandidates();