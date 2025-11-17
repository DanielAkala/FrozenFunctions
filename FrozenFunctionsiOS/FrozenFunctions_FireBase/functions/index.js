const functions = require('firebase-functions');
const { GoogleGenAI } = require('@google/genai');

// --- CHANGE THIS SECTION ---
let apiKey;
try {
    // Attempt to load the config, which works during deployment and runtime
    apiKey = functions.config().ai.api_key;
} catch (e) {
    apiKey = undefined;
}

if (!apiKey) {
    throw new Error('Firebase configuration variable ai.api_key is missing.');
}

const ai = new GoogleGenAI({ apiKey: apiKey });
const modelName = 'gemini-2.5-flash';

console.log('API Key Loaded:', apiKey ? 'Loaded' : 'NOT LOADED');

// Define the Cloud Function.
exports.generateRecipes = functions.https.onRequest(async (req, res) => {
    // Set CORS headers to allow your iOS app to call the API
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');

    // Handle CORS preflight request
    if (req.method === 'OPTIONS') {
        res.status(204).send('');
        return;
    }

    if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
    }

    try {
        const { ingredients, dietaryRestriction } = req.body;

        if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
            return res.status(400).json({ error: 'Invalid ingredients.' });
        }

        const ingredientList = ingredients.join(', ');
        const restrictionText = dietaryRestriction && dietaryRestriction !== 'None'
            ? `The recipe MUST adhere to the following dietary restriction: ${dietaryRestriction}.`
            : '';
        
        // Strict prompt forcing JSON output with required fields
        const prompt = `
            Based on the following ingredients: ${ingredientList}.
            Generate 3 unique and creative recipes. ${restrictionText}
            Also include a step by step process to make that recipe using the ingredients given!
            
            You MUST return the output as a single JSON object. 
            DO NOT include any text, comments, or markdown formatting (like triple backticks) outside of the JSON block.

            The JSON must strictly follow this format:
            {
                "recipes": [
                    {
                        "name": "Recipe Name",
                        "ingredients": ["list", "of", "all", "ingredients"],
                        "instructions": "Step-by-step instructions.",
                        "prepTime": "e.g., 20 mins",
                        "difficulty": "Easy, Medium, or Hard"
                    }
                ]
            }
        `;

        // Call the Gemini API
        const aiResponse = await ai.models.generateContent({
            model: modelName,
            contents: prompt,
            config: {
                responseMimeType: "application/json",
                responseSchema: {
                    type: "object",
                    properties: {
                        recipes: {
                            type: "array",
                            items: {
                                type: "object",
                                properties: {
                                    name: { type: "string" },
                                    ingredients: { type: "array", items: { type: "string" } },
                                    instructions: { type: "string" },
                                    prepTime: { type: "string" },
                                    difficulty: { type: "string" }
                                }
                            }
                        }
                    }
                }
            }
        });
        
        let recipes;
        try {
            // Robust JSON parsing logic
            let cleanedText = aiResponse.text.trim().replace(/^```json\s*|```\s*$/g, '').trim();
            recipes = JSON.parse(cleanedText);
        } catch (parseError) {
            console.error('JSON parse error, attempting fallback extraction:', parseError.message);
            const jsonMatch = aiResponse.text.match(/\{[\s\S]*\}/);
            if (jsonMatch) {
                recipes = JSON.parse(jsonMatch[0]);
            } else {
                throw new Error('Could not parse recipes from AI response');
            }
        }

        // Validate and ensure structure safety before sending to client
        if (!recipes || !recipes.recipes || !Array.isArray(recipes.recipes)) {
            throw new Error('Invalid recipe format from AI: Missing "recipes" array.');
        }

        return res.status(200).json(recipes);

    } catch (error) {
        console.error('Fatal error generating recipes:', error);
        return res.status(500).json({
            error: 'Failed to generate recipes',
            message: error.message,
        });
    }
});
