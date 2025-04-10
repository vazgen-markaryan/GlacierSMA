import 'sensor_card.dart';
import '../../../constants.dart';
import 'package:flutter/material.dart';
import '../../../sensors_data/sensors_data.dart';

class MySensors extends StatelessWidget {
        final String title;
        final List<CloudStorageInfo> sensors;

        const MySensors({
                super.key,
                required this.title,
                required this.sensors
        });

        @override
        Widget build(BuildContext context) {
                return Column(
                        children: [
                                Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                                Text(title, style: Theme.of(context).textTheme.titleMedium)
                                        ]
                                ),
                                SizedBox(height: defaultPadding),
                                FileInfoCardGridView(
                                        sensors: sensors,
                                        crossAxisCount: 2,
                                        childAspectRatio: 2
                                )
                        ]
                );
        }
}

class FileInfoCardGridView extends StatelessWidget {
        const FileInfoCardGridView({
                super.key,
                required this.sensors,
                this.crossAxisCount = 2,
                this.childAspectRatio = 1
        });

        final List<CloudStorageInfo> sensors;
        final int crossAxisCount;
        final double childAspectRatio;

        @override
        Widget build(BuildContext context) {
                return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: sensors.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: defaultPadding,
                                mainAxisSpacing: defaultPadding,
                                childAspectRatio: childAspectRatio
                        ),
                        itemBuilder: (context, index) => SensorCard(info: sensors[index])
                );
        }
}