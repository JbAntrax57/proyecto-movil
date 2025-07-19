-- Query para insertar 3 negocios destacados en la tabla 'negocios'
-- Estos negocios aparecerán en el slider de destacados

INSERT INTO negocios (nombre, descripcion, direccion, img, categoria, destacado) VALUES
(
    'Pizza Express',
    'Las mejores pizzas artesanales con ingredientes frescos y masa casera. Especialidad en pizzas gourmet y opciones vegetarianas.',
    'Av. Principal 123, Centro',
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=400&q=80',
    'Pizza',
    true
),
(
    'Sushi Master',
    'Sushi fresco y auténtico preparado por chefs expertos. Incluye rolls especiales, sashimi y opciones veganas.',
    'Calle Marina 456, Zona Rosa',
    'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?auto=format&fit=crop&w=400&q=80',
    'Sushi',
    true
),
(
    'Burger House',
    'Hamburguesas gourmet con carne 100% de res, pan artesanal y ingredientes premium. Incluye opciones veganas y sin gluten.',
    'Plaza Central 789, Downtown',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80',
    'Hamburguesas',
    true
);

-- Query para verificar que se insertaron correctamente
SELECT id, nombre, categoria, destacado FROM negocios WHERE destacado = true; 