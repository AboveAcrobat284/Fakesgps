import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart'; // Importa la librería logger

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPS Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GPSDetectorPage(),
    );
  }
}

class GPSDetectorPage extends StatefulWidget {
  const GPSDetectorPage({super.key});

  @override
  GPSDetectorPageState createState() => GPSDetectorPageState();
}

class GPSDetectorPageState extends State<GPSDetectorPage> {
  static const platform = MethodChannel('com.example.fakesgps/detect');

  String gpsStatus = "Checking GPS status...";
  Location location = Location();

  var logger = Logger(); // Instancia del Logger

  @override
  void initState() {
    super.initState();
    checkGPSStatus();
  }

  Future<void> checkGPSStatus() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          gpsStatus = "GPS is disabled.";
        });
        return;
      }
    }

    // Verificar los permisos de ubicación
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          gpsStatus = "Location permissions are denied.";
        });
        return;
      }
    }

    // Verificar si la ubicación es simulada (mock location)
    bool isFakeGPS = await checkIfFakeGPS();

    setState(() {
      gpsStatus = isFakeGPS ? "Fake GPS detected!" : "Real GPS in use.";
    });
  }

  Future<bool> checkIfFakeGPS() async {
  try {
    // Método para verificar si la ubicación es simulada
    final bool result = await platform.invokeMethod('isMockLocation');

    // Validaciones adicionales que puedes agregar, como velocidad, altitud o patrones inusuales
    LocationData locationData = await location.getLocation();
    if (locationData.latitude == null || locationData.longitude == null) {
      // Si no se puede obtener la latitud o longitud, podría ser un GPS falso
      return true;
    }

    // Aquí puedes agregar más validaciones personalizadas
    // Por ejemplo, verificar si las coordenadas se mantienen fijas durante un tiempo prolongado o si cambian de manera sospechosa
    if (locationData.speed != null && locationData.speed! > 100) {
      // Si la velocidad es mayor de 100 metros por segundo (360 km/h), puede ser sospechoso
      return true;
    }

    return result;
  } on PlatformException catch (e) {
    logger.e("Failed to detect mock location: '${e.message}'.");
    return false;
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GPS Detector"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gpsStatus,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                checkGPSStatus(); // Al presionar el botón se vuelve a verificar el GPS
              },
              child: const Text('Check GPS Again'),
            ),
          ],
        ),
      ),
    );
  }
}
