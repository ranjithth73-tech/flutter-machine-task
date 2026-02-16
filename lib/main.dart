import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_task_manager/app.dart';
import 'package:smart_task_manager/core/utils/constants.dart';
import 'package:smart_task_manager/features/task/data/models/task_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TaskModelAdapter());
  
  // Open Hix Box
  await Hive.openBox<TaskModel>(ApiConstants.taskBox);
  
  runApp(
    const ProviderScope(
      child: SmartTaskApp(),
    ),
  );
}
