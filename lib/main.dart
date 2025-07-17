   import 'package:flutter/material.dart';

   void main() {
     runApp(const MyApp());
   }

   class MyApp extends StatelessWidget {
     const MyApp({super.key});

     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         title: 'Flutter Demo',
         home: Scaffold(
           appBar: AppBar(
             title: const Text('Flutter Demo'),
           ),
           body: Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Text(
                   '¡Hola Mundo desde Flutter!',
                   style: TextStyle(fontSize: 24),
                 ),
                 SizedBox(height: 20),
                 Image.network(
                   'https://cdn.conmebol.com/wp-content/uploads/2014/07/066_dppi_40514041_151.jpg',
                   width: 200,
                   height: 200,
                 ),
                 SizedBox(height: 20),
                 Text(
                   '#19',
                   style: TextStyle(fontSize: 48, color: Colors.blue),
                 ),
               ],
             ),
           ),
         ),
       );
     }
   }