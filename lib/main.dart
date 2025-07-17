import 'package:flutter/material.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int contador = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Platform.isIOS
                  ? 'Estás en iOS'
                  : Platform.isAndroid
                      ? 'Estás en Android'
                      : 'Otro sistema',
              style: const TextStyle(fontSize: 20, color: Colors.green),
            ),
            const SizedBox(height: 20),
            Image.network(
              'https://cdn.conmebol.com/wp-content/uploads/2014/07/066_dppi_40514041_151.jpg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              'Contador: $contador',
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  contador++;
                });
              },
              child: const Text('Incrementar'),
            ),
            const SizedBox(height: 20),
            const Text(
              '#19',
              style: TextStyle(fontSize: 48, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}