export default async function handler(req, res) {
  // Enable CORS for iOS app
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight request
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { ingredients, dietaryRestriction } = req.body;

    // Validate input
    if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
      return res.status(400).json({ error: 'Invalid ingredients. Please provide an array of ingredient names.' });
    }

    // Validate dietary restriction
    const validRestrictions = ['None', 'Vegan', 'Vegetarian', 'Pescatarian', 'Peanut Allergy', 'Lactose Intolerance'];
    if (dietaryRestriction && !validRestrictions.includes(dietaryRestriction)) {
      return res.status(400).json({ error: 'Invalid dietary restriction' });
    }

    console.log('Generating recipes for:', ingredients.join(', '));
    console.log('Dietary restriction:', dietaryRestriction || 'None');

    // Create the prompt
    const ingredientList = ingredients.join(', ');
    const restrictionText = dietaryRestriction && dietaryRestriction !== 'None'
      ? `IMPORTANT: The recipe MUST be ${dietaryRestriction}-friendly. Do not include any ingredients that violate this restriction.`
      : '';

    const prompt = `You are a helpful chef assistant. Generate exactly 3 creative and realistic recipes using ONLY these available ingredients: ${ingredientList}.

${restrictionText}

CRITICAL: Return ONLY valid JSON in this EXACT format with NO other text, explanation, or markdown:
{
  "recipes": [
    {
      "name": "Recipe Name Here",
      "ingredients": ["ingredient1", "ingredient2", "ingredient3"],
      "instructions": "Detailed step-by-step cooking instructions here. Be specific and clear.",
      "prepTime": "X minutes",
      "difficulty": "Easy"
    }
  ]
}

STRICT RULES:
1. Use ONLY the ingredients from this list: ${ingredientList}
2. Each recipe must use at least 2 ingredients from the list
3. Generate exactly 3 different recipes
4. Make recipes realistic and practical for home cooking
5. Instructions should be clear and detailed (3-5 sentences minimum)
6. prepTime should be realistic (e.g., "15 minutes", "30 minutes", "1 hour")
7. difficulty must be one of: "Easy", "Medium", "Hard"
8. ${restrictionText}
9. Return ONLY the JSON, no markdown code blocks, no explanations`;

    // Get API key from environment variable
    const apiKey = process.env.AIzaSyChBtAXzCfEZHbtgHQUsyyzHKhZn7UrMxc;
    
    if (!apiKey) {
      console.error('GEMINI_API_KEY not found in environment variables');
      return res.status(500).json({
        error: 'Server configuration error',
        message: 'API key not configured. Please add GEMINI_API_KEY to Vercel environment variables.'
      });
    }

    // Call Google Gemini API
    console.log('Calling Gemini API...');
    const geminiResponse = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: prompt }
              ]
            }
          ],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 2048,
          }
        })
      }
    );

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      console.error('Gemini API error:', geminiResponse.status, errorText);
      throw new Error(`Gemini API error: ${geminiResponse.status} - ${errorText}`);
    }

    const data = await geminiResponse.json();
    console.log('Received response from Gemini API');
    
    // Parse the response
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      console.error('No text in Gemini response:', JSON.stringify(data));
      throw new Error('No response text from Gemini');
    }

    console.log('Raw response:', text.substring(0, 200) + '...');

    // Clean up the response (remove markdown code blocks if present)
    let cleanedText = text
      .replace(/```json\s*/g, '')
      .replace(/```\s*/g, '')
      .trim();

    // Try to parse the JSON
    let recipes;
    try {
      recipes = JSON.parse(cleanedText);
    } catch (parseError) {
      console.error('JSON parse error:', parseError.message);
      console.error('Cleaned text:', cleanedText.substring(0, 500));
      
      // Try to extract JSON from the text
      const jsonMatch = cleanedText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        recipes = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('Could not parse recipes from response');
      }
    }

    // Validate the response structure
    if (!recipes || !recipes.recipes || !Array.isArray(recipes.recipes)) {
      console.error('Invalid recipe structure:', JSON.stringify(recipes));
      throw new Error('Invalid recipe format from AI');
    }

    // Ensure all recipes have required fields
    recipes.recipes = recipes.recipes.map((recipe, index) => ({
      name: recipe.name || `Recipe ${index + 1}`,
      ingredients: Array.isArray(recipe.ingredients) ? recipe.ingredients : [],
      instructions: recipe.instructions || 'No instructions provided',
      prepTime: recipe.prepTime || '30 minutes',
      difficulty: ['Easy', 'Medium', 'Hard'].includes(recipe.difficulty) ? recipe.difficulty : 'Easy'
    }));

    console.log(`Successfully generated ${recipes.recipes.length} recipes`);

    // Return the recipes
    return res.status(200).json(recipes);

  } catch (error) {
    console.error('Error generating recipes:', error);
    return res.status(500).json({
      error: 'Failed to generate recipes',
      message: error.message || 'Unknown error occurred'
    });
  }
}
