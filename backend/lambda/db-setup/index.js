// LibraryFinder - Database Setup Lambda Function
// Creates tables and inserts sample library data

const { Client } = require('pg');

// Database connection from environment variables
const client = new Client({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: {
    rejectUnauthorized: false // RDS requires SSL
  }
});

exports.handler = async (event) => {
  console.log('Starting database setup...');
  
  try {
    // Connect to database
    await client.connect();
    console.log('Connected to database successfully');
    
    // Create libraries table
    await client.query(`
      CREATE TABLE IF NOT EXISTS libraries (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        address VARCHAR(500),
        city VARCHAR(100),
        state VARCHAR(50),
        zip_code VARCHAR(10),
        phone VARCHAR(20),
        website VARCHAR(500),
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('✅ Libraries table created');
    
    // Create indexes for faster searches
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_libraries_city ON libraries(city);
      CREATE INDEX IF NOT EXISTS idx_libraries_state ON libraries(state);
      CREATE INDEX IF NOT EXISTS idx_libraries_zip ON libraries(zip_code);
    `);
    console.log('✅ Indexes created');
    
    // Check if we already have data
    const countResult = await client.query('SELECT COUNT(*) FROM libraries');
    const count = parseInt(countResult.rows[0].count);
    
    if (count === 0) {
      // Insert sample library data
      await client.query(`
        INSERT INTO libraries (name, address, city, state, zip_code, phone, website, latitude, longitude)
        VALUES
          ('Houston Public Library - Central', '500 McKinney St', 'Houston', 'TX', '77002', '(832) 393-1313', 'https://houstonlibrary.org', 29.7604, -95.3698),
          ('Harris County Public Library - Barbara Bush', '6817 Cypresswood Dr', 'Spring', 'TX', '77379', '(281) 290-3210', 'https://www.hcpl.net', 30.0599, -95.5133),
          ('Houston Public Library - Heights', '1302 Heights Blvd', 'Houston', 'TX', '77008', '(832) 393-1940', 'https://houstonlibrary.org', 29.7833, -95.4022),
          ('Houston Public Library - Montrose', '4100 Montrose Blvd', 'Houston', 'TX', '77006', '(832) 393-1950', 'https://houstonlibrary.org', 29.7378, -95.3897),
          ('Fort Bend County Libraries - George Memorial', '1001 Golfview Dr', 'Richmond', 'TX', '77469', '(281) 341-2640', 'https://www.fortbend.lib.tx.us', 29.5821, -95.7611),
          ('New York Public Library - Stephen A. Schwarzman', '476 5th Ave', 'New York', 'NY', '10018', '(917) 275-6975', 'https://www.nypl.org', 40.7532, -73.9822),
          ('Los Angeles Public Library - Central', '630 W 5th St', 'Los Angeles', 'CA', '90071', '(213) 228-7000', 'https://www.lapl.org', 34.0522, -118.2437),
          ('Chicago Public Library - Harold Washington', '400 S State St', 'Chicago', 'IL', '60605', '(312) 747-4300', 'https://www.chipublib.org', 41.8756, -87.6279),
          ('San Francisco Public Library - Main', '100 Larkin St', 'San Francisco', 'CA', '94102', '(415) 557-4400', 'https://sfpl.org', 37.7793, -122.4158),
          ('Seattle Public Library - Central', '1000 4th Ave', 'Seattle', 'WA', '98104', '(206) 386-4636', 'https://www.spl.org', 47.6062, -122.3321);
      `);
      console.log('✅ Sample data inserted: 10 libraries');
    } else {
      console.log(`ℹ️ Database already has ${count} libraries, skipping sample data`);
    }
    
    // Verify the setup
    const verifyResult = await client.query('SELECT COUNT(*) FROM libraries');
    const totalLibraries = verifyResult.rows[0].count;
    
    const response = {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Database setup completed successfully!',
        tables_created: ['libraries'],
        indexes_created: ['idx_libraries_city', 'idx_libraries_state', 'idx_libraries_zip'],
        total_libraries: totalLibraries,
        timestamp: new Date().toISOString()
      })
    };
    
    console.log('Database setup completed successfully');
    return response;
    
  } catch (error) {
    console.error('Error setting up database:', error);
    
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Database setup failed',
        error: error.message,
        stack: error.stack
      })
    };
    
  } finally {
    // Close connection
    await client.end();
    console.log('Database connection closed');
  }
};
