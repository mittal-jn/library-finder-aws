// Lambda function to search libraries in PostgreSQL database
// Handles search by city, state, or ZIP code
// Returns JSON results with CORS headers for frontend

const { Client } = require('pg');

const dbConfig = {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS'
};

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  if (event.requestContext?.http?.method === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }
  
  const client = new Client(dbConfig);
  
  try {
    await client.connect();
    console.log('Connected to database');
    
    const params = event.queryStringParameters || {};
    
    const conditions = [];
    const values = [];
    let paramCount = 1;
    
    if (params.city) {
      conditions.push(`LOWER(city) LIKE LOWER($${paramCount})`);
      values.push(`%${params.city}%`);
      paramCount++;
    }
    
    if (params.state) {
      conditions.push(`LOWER(state) = LOWER($${paramCount})`);
      values.push(params.state);
      paramCount++;
    }
    
    if (params.zip_code || params.zip) {
      conditions.push(`zip_code = $${paramCount}`);
      values.push(params.zip_code || params.zip);
      paramCount++;
    }
    
    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    
    const query = `SELECT * FROM libraries ${whereClause} ORDER BY city, name LIMIT 100`;
    
    const result = await client.query(query, values);
    console.log(`Found ${result.rows.length} libraries`);
    
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      body: JSON.stringify({
        success: true,
        count: result.rows.length,
        libraries: result.rows
      })
    };
    
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      },
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
    
  } finally {
    await client.end();
  }
};