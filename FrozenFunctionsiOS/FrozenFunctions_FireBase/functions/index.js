const functions = require('firebase-functions');
const { GoogleGenAI } = require('@google/genai');

const modelName = 'gemini-1.5-flash';
exports.generateRecipes = functions.https.onRequest(
    {
        secrets: ['GEMINI_API_KEY'],
        timeoutSeconds: 180,
        memory: '512MiB'
    },
    async (req, res) => {
        // Set CORS headers
        res.set('Access-Control-Allow-Origin', '*');
        res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
        res.set('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method === 'OPTIONS') {
            res.status(204).send('');
            return;
        }

        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        // --- SECURE API KEY LOADING ---
        const apiKey = process.env.GEMINI_API_KEY;
        
        // Critical Security Check
        if (!apiKey) {
            console.error('CRITICAL: GEMINI_API_KEY environment variable is not set.');
            return res.status(500).json({ error: 'Server configuration error: GEMINI_API_KEY missing.' });
        }

        // Initialize the client
        const ai = new GoogleGenAI({ apiKey: apiKey });
        // --- END SECURE API KEY LOADING ---
        
        try {
            const { ingredients, dietaryRestriction } = req.body;

            if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
                return res.status(400).json({ error: 'Invalid ingredients.' });
            }

            const ingredientList = ingredients.join(', ');
            const restrictionText = dietaryRestriction && dietaryRestriction !== 'None'
                ? `The recipe MUST adhere to the following dietary restriction: ${dietaryRestriction}.`
                : '';
            
            const prompt = `
                Based on the following ingredients: ${ingredientList}.
                Generate 3 unique and creative recipes. ${restrictionText}
                Also include a step by step process to make that recipe using the ingredients given!
                
                You **MUST** return the output as a single, raw JSON object. 
                **DO NOT** include any text, comments, or markdown formatting (like triple backticks \`\`\`) outside of the JSON block.
                
                The JSON must strictly follow the response schema provided in the configuration.
            `;

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
                                description: "A list of unique recipes.",
                                items: {
                                    type: "object",
                                    properties: {
                                        name: { type: "string", description: "The name of the recipe." },
                                        ingredients: { type: "array", items: { type: "string" }, description: "List of all required ingredients." },
                                        instructions: { type: "string", description: "Step-by-step instructions for the recipe." },
                                        prepTime: { type: "string", description: "Estimated preparation time (e.g., '20 mins')." },
                                        difficulty: { type: "string", description: "Difficulty level (Easy, Medium, or Hard)." }
                                    },
                                    required: ["name", "ingredients", "instructions", "prepTime", "difficulty"]
                                }
                            }
                        },
                        required: ["recipes"]
                    }
                }
            });
            
            let recipes;
            let rawText = aiResponse.text.trim();
            
            // --- STRICT JSON PARSING ---
            try {
                let cleanedText = rawText.replace(/^```json\s*|```\s*$/g, '').trim();
                recipes = JSON.parse(cleanedText);
            } catch (parseError) {
                console.warn('Primary JSON parse failed. Attempting fallback extraction:', parseError.message);
                
                const jsonMatch = rawText.match(/\{[\s\S]*\}/);
                if (jsonMatch) {
                    try {
                         recipes = JSON.parse(jsonMatch[0]);
                    } catch (fallbackParseError) {
                        console.error('Fallback JSON parse also failed:', fallbackParseError.message);
                        throw new Error('Could not parse recipes from AI response. Raw text snippet: ' + rawText.substring(0, 100) + '...');
                    }
                } else {
                    throw new Error('Could not parse recipes from AI response. No JSON object found.');
                }
            }
            // --- END STRICT JSON PARSING ---

            if (!recipes || !recipes.recipes || !Array.isArray(recipes.recipes)) {
                console.error('AI response failed final validation. Content:', JSON.stringify(recipes).substring(0, 200) + '...');
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
    }
);
