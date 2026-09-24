Flutter E-Commerce Shop

A full-stack electronics e-commerce demo built with Flutter Web, Dart, Node.js, Express and MySQL 8. The project contains a customer storefront, membership authentication, persistent carts, order history and a separate protected admin system.

Features

Customer

Responsive electronics storefront

Product categories, search and skeleton loading

Customer registration and login

Persistent JWT session

Member cart saved in MySQL

Checkout and order history

Admin

Separate admin login at /admin/login

Protected admin routes

Dashboard with revenue, orders, customers and inventory statistics

Product create, edit, hide, delete and image upload

Order, customer and sales API endpoints

Technology

Layer

Technology

Frontend

Flutter Web, Dart, Riverpod, GoRouter

Backend

Node.js 22+, Express 5

Database

MySQL 8.0

Authentication

JWT and bcrypt

File upload

Multer

Project structure

flutter_e-commerce_shop/
├── backend/
│   ├── database/schema.sql
│   ├── src/
│   ├── uploads/products/
│   ├── .env.example
│   └── package.json
├── frontend/
│   ├── lib/
│   ├── web/
│   └── pubspec.yaml
└── README.md

1. Required software

Install the following before continuing:

Git

Node.js 22 or newer

Flutter SDK

Google Chrome

MySQL Community Server 8.0

MySQL Workbench

Visual Studio Code with the Flutter and Dart extensions

Verify the installations:

git --version
node --version
npm --version
flutter --version
flutter doctor
mysql --version

Resolve any important issue reported by flutter doctor before running the frontend.

2. Download the project

Open PowerShell, Command Prompt or the VS Code terminal:

git clone https://github.com/NguyenLamDuongTung/flutter_e-commerce_shop.git
cd flutter_e-commerce_shop

Alternatively, select Code → Download ZIP on GitHub, extract the ZIP and open the extracted folder in VS Code.

3. Create the MySQL database

Option A: MySQL Workbench

Start MySQL Server.

Open MySQL Workbench.

Open your local MySQL connection.

Select File → Open SQL Script.

Open backend/database/schema.sql.

Click the lightning icon to execute the entire script.

Refresh the SCHEMAS panel.

Confirm that flutter_shop_db exists.

Option B: MySQL command line

From the project root, run:

mysql -u root -p < backend/database/schema.sql

Enter your MySQL password when requested.

The database contains these tables:

users
categories
products
product_images
carts
cart_items
orders
order_items

4. Configure and install the backend

Open a terminal in the project root:

cd backend
npm install

Create the local environment file.

PowerShell:

Copy-Item .env.example .env

Command Prompt:

copy .env.example .env

macOS/Linux:

cp .env.example .env

Open backend/.env and configure it:

NODE_ENV=development
PORT=8081
CLIENT_URL=http://localhost:8080

DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=YOUR_MYSQL_PASSWORD
DB_NAME=flutter_shop_db

JWT_SECRET=REPLACE_WITH_A_LONG_RANDOM_SECRET
JWT_EXPIRES_IN=7d

UPLOAD_DIRECTORY=uploads/products
MAX_IMAGE_SIZE_MB=5

Replace YOUR_MYSQL_PASSWORD with your own MySQL password. Do not copy another developer's password.

Generate a JWT secret with Node.js:

node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

Copy the generated string into JWT_SECRET.

Never commit backend/.env to GitHub.

5. Add demo data and the admin account

Make sure MySQL is running, then execute inside backend:

npm run seed

The seed command creates categories, demo products and this development admin account:

Email: admin@fluttershop.com
Password: Admin@123456

This account is for local demonstration only. Change its password before a real deployment.

6. Start the backend

Development mode with automatic restart:

npm run dev

Expected output:

MySQL database connected.
Flutter Shop API running on http://localhost:8081

Test the API in a browser:

http://localhost:8081/
http://localhost:8081/api/health
http://localhost:8081/api/products

Keep this terminal running.

7. Install frontend libraries

Open a second terminal from the project root:

cd frontend
flutter clean
flutter pub get
dart format lib
flutter analyze

flutter pub get installs the packages listed in frontend/pubspec.yaml, including Riverpod, GoRouter, HTTP, shared preferences, cached images, shimmer loading, charts and file picker.

8. Run Flutter Web

The backend uses port 8081, so start Flutter Web on port 8080:

flutter run -d chrome --web-port=8080

Open these URLs:

Page

URL

Customer store

http://localhost:8080/

Customer login

http://localhost:8080/login

Customer registration

http://localhost:8080/register

Admin login

http://localhost:8080/admin/login

Admin dashboard

http://localhost:8080/admin

Product management

http://localhost:8080/admin/products

Do not run the frontend and backend on the same port.

9. Normal startup after the first installation

For future runs, you only need two terminals.

Terminal 1:

cd flutter_e-commerce_shop/backend
npm run dev

Terminal 2:

cd flutter_e-commerce_shop/frontend
flutter run -d chrome --web-port=8080

You do not need to run npm install, flutter pub get, the SQL schema or the seed command every time.

10. Common errors

Access denied for user 'root'@'localhost'

The DB_USER or DB_PASSWORD value in backend/.env is incorrect. Test the same account in MySQL Workbench and update .env.

Unknown database 'flutter_shop_db'

Run backend/database/schema.sql in MySQL Workbench.

Table ... doesn't exist

The database exists but the schema was not imported. Execute the entire schema.sql, not only its first line.

Missing environment variable

Make sure the file is named exactly .env and is located inside backend.

CORS error in Chrome

Use exactly these ports:

Frontend: http://localhost:8080
Backend:  http://localhost:8081

Also confirm:

CLIENT_URL=http://localhost:8080

Restart the backend after changing .env.

ERR_CONNECTION_REFUSED

The Node.js backend is not running. Open the backend terminal and run npm run dev.

Flutter packages or generated files are broken

cd frontend
flutter clean
flutter pub get

Then restart the Dart analysis server in VS Code with Ctrl+Shift+P → Dart: Restart Analysis Server.

Port 8080 is already in use

Stop the previous Flutter process with Ctrl+C. On Windows, you can inspect the port with:

netstat -ano | findstr :8080

Admin login succeeds but redirects to the store

Confirm that you used the seeded admin account, not the MySQL root account. Then clear the browser storage for localhost:8080, restart Flutter and log in again.

11. Useful development commands

Backend:

npm run dev
npm run start
npm run seed
npm test

Frontend:

flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d chrome --web-port=8080
flutter build web --release

12. Security notes

Never upload backend/.env to GitHub.

Never publish your MySQL root password or JWT secret.

Use a separate MySQL user with limited permissions for production.

Replace the demo admin password before deployment.

Local files in backend/uploads should be replaced by cloud storage for production deployment.

License

This repository is an educational midterm demo project.
