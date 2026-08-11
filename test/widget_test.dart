import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plataforma Educativa',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Row(
        children: [
          // Sección de Alumnos a la izquierda
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AlumnosMenuPage()),
                );
              },
              child: Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Alumnos',
                    style: TextStyle(color: Colors.black, fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
          // Sección de Instituciones a la derecha
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InstitucionesMenuPage(),
                  ),
                );
              },
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'Instituciones',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Página del menú para alumnos con los dos botones
class AlumnosMenuPage extends StatelessWidget {
  const AlumnosMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alumnos')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Aquí iría la navegación al login de alumnos
              },
              child: const Text('Ingresar'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la navegación al registro de alumnos
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}

// Página del menú para instituciones con los dos botones
class InstitucionesMenuPage extends StatelessWidget {
  const InstitucionesMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instituciones')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // Aquí iría la navegación al login de instituciones
              },
              child: const Text('Ingresar'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Aquí iría la navegación al registro de instituciones
              },
              child: const Text('Registrarse'),
            ),
          ],
        ),
      ),
    );
  }
}
