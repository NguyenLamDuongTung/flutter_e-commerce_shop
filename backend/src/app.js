import path from 'node:path';
import { fileURLToPath } from 'node:url';

import compression from 'compression';
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import morgan from 'morgan';
import adminProductRoutes from './routes/admin-product.routes.js';
import productRoutes from './routes/product.routes.js';

import cartRoutes from './routes/cart.routes.js';
import orderRoutes from './routes/order.routes.js';

import { env } from './config/env.js';
import {
  errorHandler,
  notFoundHandler,
} from './middleware/errorHandler.js';
import adminRoutes from './routes/admin.routes.js';
import authRoutes from './routes/auth.routes.js';

const currentFile = fileURLToPath(import.meta.url);
const currentDirectory = path.dirname(currentFile);
const backendDirectory = path.resolve(currentDirectory, '..');

const app = express();

app.disable('x-powered-by');

app.use(
  helmet({
    crossOriginResourcePolicy: {
      policy: 'cross-origin',
    },
  }),
);

app.use(compression());

const configuredOrigins = env.clientUrl
  .split(',')
  .map((origin) => origin.trim().replace(/\/$/, ''))
  .filter(Boolean);

const developmentOrigins = [
  'http://localhost:8080',
  'http://127.0.0.1:8080',
];

const allowedOrigins = new Set([
  ...configuredOrigins,
  ...(env.nodeEnv === 'development' ? developmentOrigins : []),
]);

app.use(
  cors({
    origin(origin, callback) {
      // Requests without Origin are server-to-server tools such as curl.
      if (!origin || allowedOrigins.has(origin.replace(/\/$/, ''))) {
        callback(null, true);
        return;
      }

      callback(new Error(`CORS blocked origin: ${origin}`));
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    optionsSuccessStatus: 204,
  }),
);

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(morgan(env.nodeEnv === 'production' ? 'combined' : 'dev'));

app.use(
  '/uploads',
  express.static(path.join(backendDirectory, 'uploads'), {
    maxAge: env.nodeEnv === 'production' ? '7d' : 0,
  }),
);

app.get('/', (request, response) => {
  response.json({
    success: true,
    message: 'Welcome to Flutter Shop API.',
    documentation: {
      health: '/api/health',
      products: '/api/products',
      categories: '/api/products/categories',
    },
  });
});

app.use('/api/auth', authRoutes);

app.use('/api/products', productRoutes);

app.use('/api/cart', cartRoutes);
app.use('/api/orders', orderRoutes);

app.use('/api/admin/products', adminProductRoutes);
app.use('/api/admin', adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;