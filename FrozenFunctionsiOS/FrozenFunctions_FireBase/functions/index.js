const { onRequest } = require('firebase-functions/v2/https');
const nodemailer = require('nodemailer');
const { defineSecret } = require('firebase-functions/params');

// Use gemini-1.5-flash-8b with v1beta API
const modelName = 'gemini-2.5-flash';
// Define secrets
const geminiApiKey = defineSecret('GEMINI_API_KEY');
const emailUser = defineSecret('EMAIL_USER');
const emailPassword = defineSecret('EMAIL_PASSWORD');

// ========================================
// FUNCTION 1: Generate Recipes
// ========================================
exports.generateRecipes = onRequest(
    {
        secrets: [geminiApiKey],
        timeoutSeconds: 180,
        memory: '512MiB',
        cors: true
    },
    async (req, res) => {
        if (req.method === 'OPTIONS') {
            res.status(204).send('');
            return;
        }

        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        const apiKey = geminiApiKey.value();
        
        if (!apiKey) {
            console.error('CRITICAL: GEMINI_API_KEY environment variable is not set.');
            return res.status(500).json({ error: 'Server configuration error: GEMINI_API_KEY missing.' });
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
            
            const prompt = `You are a creative chef assistant. Based on the available ingredients, generate 3-5 unique and practical recipes.

Available ingredients: ${ingredientList}
${restrictionText}

RECIPE REQUIREMENTS:
- Generate between 3-5 recipes (quality over quantity - only create recipes that make sense)
- Each recipe should use SOME (not necessarily ALL) of the available ingredients
- Recipes should be practical and actually cookable with the given ingredients
- You may assume basic pantry staples (oil, salt, pepper, water) are available
- Each recipe must be unique and different from the others
- Prioritize recipes that use more of the available ingredients

RECIPE FORMAT:
- Name: Clear, appetizing recipe name
- Ingredients: List ALL ingredients needed (including basic staples if required)
- Instructions: Clear, numbered step-by-step cooking instructions
- PrepTime: Realistic preparation time (e.g., "15 mins", "30 mins", "1 hour")
- Difficulty: Must be one of: "Easy", "Medium", or "Hard"

CRITICAL: Return ONLY a valid JSON object with NO additional text, comments, or markdown formatting.

Example format:
{
    "recipes": [
        {
            "name": "Recipe Name",
            "ingredients": ["ingredient 1", "ingredient 2"],
            "instructions": "Step 1: ... Step 2: ...",
            "prepTime": "20 mins",
            "difficulty": "Easy"
        }
    ]
}`;

            console.log('Calling Gemini API with model:', modelName);

            // Use v1beta REST API directly
            const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    contents: [{
                        parts: [{
                            text: prompt
                        }]
                    }],
                    generationConfig: {
                        temperature: 0.7,
                        topK: 40,
                        topP: 0.95,
                        maxOutputTokens: 2048,
                    }
                })
            });

            if (!response.ok) {
                const errorText = await response.text();
                console.error('Gemini API error:', response.status, errorText);
                throw new Error(`Gemini API returned ${response.status}: ${errorText}`);
            }

            const data = await response.json();
            
            if (!data.candidates || !data.candidates[0] || !data.candidates[0].content) {
                console.error('Unexpected API response structure:', JSON.stringify(data).substring(0, 200));
                throw new Error('Invalid response structure from Gemini API');
            }

            const text = data.candidates[0].content.parts[0].text;
            console.log(`Received response from AI (first 200 chars): ${text.substring(0, 200)}`);
            
            let recipes;
            
            try {
                let cleanedText = text.trim().replace(/^```json\s*|```\s*$/g, '').trim();
                recipes = JSON.parse(cleanedText);
            } catch (parseError) {
                console.warn('Primary JSON parse failed. Attempting fallback extraction:', parseError.message);
                
                const jsonMatch = text.match(/\{[\s\S]*\}/);
                if (jsonMatch) {
                    try {
                         recipes = JSON.parse(jsonMatch[0]);
                    } catch (fallbackParseError) {
                        console.error('Fallback JSON parse also failed:', fallbackParseError.message);
                        throw new Error('Could not parse recipes from AI response. Raw text snippet: ' + text.substring(0, 100) + '...');
                    }
                } else {
                    throw new Error('Could not parse recipes from AI response. No JSON object found.');
                }
            }

            if (!recipes || !recipes.recipes || !Array.isArray(recipes.recipes)) {
                console.error('AI response failed final validation. Content:', JSON.stringify(recipes).substring(0, 200) + '...');
                throw new Error('Invalid recipe format from AI: Missing "recipes" array.');
            }

            console.log(`✅ Successfully generated ${recipes.recipes.length} recipes`);
            return res.status(200).json(recipes);

        } catch (error) {
            console.error('Fatal error generating recipes:', error);
            console.error('Error details:', {
                message: error.message,
                stack: error.stack
            });
            return res.status(500).json({
                error: 'Failed to generate recipes',
                message: error.message,
            });
        }
    }
);

// ========================================
// FUNCTION 2: Send Verification Code
// ========================================
exports.sendVerificationCode = onRequest(
    {
        secrets: [emailUser, emailPassword],
        timeoutSeconds: 60,
        memory: '256MiB',
        cors: true
    },
    async (req, res) => {
        if (req.method === 'OPTIONS') {
            res.status(204).send('');
            return;
        }
        
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }
        
        try {
            const { email } = req.body;
            
            if (!email || !email.includes('@')) {
                return res.status(400).json({ error: 'Invalid email address' });
            }
            
            const code = Math.floor(100000 + Math.random() * 900000).toString();
            
            const user = emailUser.value();
            const password = emailPassword.value();
            
            if (!user || !password) {
                console.error('Email configuration missing');
                return res.status(500).json({ error: 'Email service not configured' });
            }
            
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: { user, pass: password }
            });
            
            const mailOptions = {
                from: `FrozenFunctions <${user}>`,
                to: email,
                subject: 'Your FrozenFunctions Verification Code',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
                        <div style="background-color: #13274D; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                            <h1 style="color: white; margin: 0;">🧊 FrozenFunctions</h1>
                        </div>
                        <div style="background-color: white; padding: 40px; border-radius: 0 0 10px 10px;">
                            <h2 style="color: #13274D; margin-top: 0;">Verify Your Email</h2>
                            <p style="color: #333; font-size: 16px;">Your verification code is:</p>
                            <div style="background: #f0f0f0; padding: 25px; text-align: center; border-radius: 8px; margin: 20px 0;">
                                <h1 style="letter-spacing: 10px; font-size: 36px; color: #13274D; margin: 0;">${code}</h1>
                            </div>
                            <p style="color: #666; font-size: 14px;">This code will expire in 10 minutes.</p>
                        </div>
                    </div>
                `
            };
            
            await transporter.sendMail(mailOptions);
            console.log(`✅ Verification code sent to ${email}: ${code}`);
            
            return res.status(200).json({
                success: true,
                code: code,
                message: 'Verification code sent'
            });
            
        } catch (error) {
            console.error('❌ Error sending verification email:', error);
            return res.status(500).json({
                error: 'Failed to send verification code',
                message: error.message
            });
        }
    }
);

// ========================================
// FUNCTION 3: Send Password Reset Email
// ========================================
exports.sendPasswordReset = onRequest(
    {
        secrets: [emailUser, emailPassword],
        timeoutSeconds: 60,
        memory: '256MiB',
        cors: true
    },
    async (req, res) => {
        if (req.method === 'OPTIONS') {
            res.status(204).send('');
            return;
        }
        
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }
        
        try {
            const { email, resetLink } = req.body;
            
            if (!email || !email.includes('@')) {
                return res.status(400).json({ error: 'Invalid email address' });
            }
            
            if (!resetLink) {
                return res.status(400).json({ error: 'Reset link is required' });
            }
            
            const user = emailUser.value();
            const password = emailPassword.value();
            
            if (!user || !password) {
                console.error('Email configuration missing');
                return res.status(500).json({ error: 'Email service not configured' });
            }
            
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: { user, pass: password }
            });
            
            const mailOptions = {
                from: `FrozenFunctions <${user}>`,
                to: email,
                subject: 'Reset Your FrozenFunctions Password',
                html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
                        <div style="background-color: #13274D; padding: 30px; border-radius: 10px 10px 0 0; text-align: center;">
                            <h1 style="color: white; margin: 0;">🧊 FrozenFunctions</h1>
                        </div>
                        <div style="background-color: white; padding: 40px; border-radius: 0 0 10px 10px;">
                            <h2 style="color: #13274D; margin-top: 0;">Reset Your Password</h2>
                            <p style="color: #333; font-size: 16px;">Click the button below to create a new password:</p>
                            <div style="text-align: center; margin: 30px 0;">
                                <a href="${resetLink}" style="display: inline-block; padding: 15px 30px; background-color: #13274D; color: white; text-decoration: none; border-radius: 8px; font-weight: bold;">Reset Password</a>
                            </div>
                            <p style="color: #666; font-size: 14px;">This link will expire in 1 hour.</p>
                        </div>
                    </div>
                `
            };
            
            await transporter.sendMail(mailOptions);
            console.log(`✅ Password reset email sent to ${email}`);
            
            return res.status(200).json({
                success: true,
                message: 'Password reset email sent'
            });
            
        } catch (error) {
            console.error('❌ Error sending password reset email:', error);
            return res.status(500).json({
                error: 'Failed to send password reset email',
                message: error.message
            });
        }
    }
);
