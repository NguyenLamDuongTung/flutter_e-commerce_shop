import bcrypt from 'bcryptjs';

import { database } from './config/database.js';
import { verifyDatabaseConnection } from './config/database.js';

const categories = [
  ['Phones', 'phones', 1],
  ['Laptops', 'laptops', 2],
  ['Tablets', 'tablets', 3],
  ['Watches', 'watches', 4],
  ['Audio', 'audio', 5],
  ['Accessories', 'accessories', 6],
];

const products = [
  {
    category: 'phones',
    name: 'Nova Phone Pro',
    slug: 'nova-phone-pro',
    shortDescription: 'Titanium design. Professional camera system.',
    price: 29990000,
    comparePrice: 32990000,
    stock: 25,
    featured: true,
    image:
      'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=1200&q=80',
  },
  {
    category: 'laptops',
    name: 'NovaBook Air',
    slug: 'novabook-air',
    shortDescription: 'Thin, light and ready for everything.',
    price: 26990000,
    comparePrice: null,
    stock: 18,
    featured: true,
    image:
      'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=1200&q=80',
  },
  {
    category: 'tablets',
    name: 'NovaPad Pro',
    slug: 'novapad-pro',
    shortDescription: 'A powerful and flexible creative canvas.',
    price: 21990000,
    comparePrice: 23990000,
    stock: 16,
    featured: true,
    image:
      'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?auto=format&fit=crop&w=1200&q=80',
  },
  {
    category: 'watches',
    name: 'Nova Watch',
    slug: 'nova-watch',
    shortDescription: 'Health, fitness and notifications on your wrist.',
    price: 10990000,
    comparePrice: null,
    stock: 30,
    featured: true,
    image:
      'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=1200&q=80',
  },
  {
    category: 'audio',
    name: 'Nova Pods Pro',
    slug: 'nova-pods-pro',
    shortDescription: 'Immersive sound with active noise cancellation.',
    price: 5990000,
    comparePrice: 6490000,
    stock: 45,
    featured: false,
    image:
      'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?auto=format&fit=crop&w=1200&q=80',
  },
];

async function seed() {
  try {
    await verifyDatabaseConnection();

    const adminEmail = 'admin@fluttershop.com';
    const adminPassword = 'Admin@123456';
    const adminPasswordHash = await bcrypt.hash(adminPassword, 12);

    await database.execute(
      `
        INSERT INTO users (
          full_name,
          email,
          password_hash,
          role,
          is_active
        )
        VALUES (?, ?, ?, 'admin', TRUE)
        ON DUPLICATE KEY UPDATE
          full_name = VALUES(full_name),
          password_hash = VALUES(password_hash),
          role = 'admin',
          is_active = TRUE
      `,
      ['System Administrator', adminEmail, adminPasswordHash],
    );

    for (const [name, slug, displayOrder] of categories) {
      await database.execute(
        `
          INSERT INTO categories (
            name,
            slug,
            display_order,
            is_active
          )
          VALUES (?, ?, ?, TRUE)
          ON DUPLICATE KEY UPDATE
            name = VALUES(name),
            display_order = VALUES(display_order),
            is_active = TRUE
        `,
        [name, slug, displayOrder],
      );
    }

    const [categoryRows] = await database.execute(
      'SELECT id, slug FROM categories',
    );

    const categoryIds = Object.fromEntries(
      categoryRows.map((category) => [
        category.slug,
        category.id,
      ]),
    );

    for (const product of products) {
      await database.execute(
        `
          INSERT INTO products (
            category_id,
            name,
            slug,
            short_description,
            description,
            price,
            compare_price,
            stock_quantity,
            featured,
            is_active
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TRUE)
          ON DUPLICATE KEY UPDATE
            category_id = VALUES(category_id),
            name = VALUES(name),
            short_description = VALUES(short_description),
            price = VALUES(price),
            compare_price = VALUES(compare_price),
            stock_quantity = VALUES(stock_quantity),
            featured = VALUES(featured),
            is_active = TRUE
        `,
        [
          categoryIds[product.category],
          product.name,
          product.slug,
          product.shortDescription,
          product.shortDescription,
          product.price,
          product.comparePrice,
          product.stock,
          product.featured,
        ],
      );

      const [productRows] = await database.execute(
        'SELECT id FROM products WHERE slug = ? LIMIT 1',
        [product.slug],
      );

      const productId = productRows[0].id;

      const [imageRows] = await database.execute(
        `
          SELECT id
          FROM product_images
          WHERE product_id = ? AND is_primary = TRUE
          LIMIT 1
        `,
        [productId],
      );

      if (imageRows.length === 0) {
        await database.execute(
          `
            INSERT INTO product_images (
              product_id,
              image_url,
              alt_text,
              display_order,
              is_primary
            )
            VALUES (?, ?, ?, 0, TRUE)
          `,
          [productId, product.image, product.name],
        );
      }
    }

    console.log('Seed data created successfully.');
    console.log('Admin URL: http://localhost:3000/admin/login');
    console.log(`Admin email: ${adminEmail}`);
    console.log(`Admin password: ${adminPassword}`);
  } catch (error) {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  } finally {
    await database.end();
  }
}

seed();