#!/usr/bin/env python
"""
This is a metrics gathering script that pulls in data from both of the PURE storage devices
in our DUBLIN datacenter and stores in our influxdb datastore.  This is only intended to run on production,
because there's really no notion of a staging PURE device; however, it is safe to run in staging for testing purposes.

The script iterates through both PURES, getting overall utilization info for the array (particularly "system" space),
as well as reporting utilization and IO info for each volume by name.

We then send the data on to the local sensu client's port 3030, which then relays to the sensu server and influxdb
beyond.

NOTE(s):
  - this script is only intended to run on a/the sensu "primary" server

"""

from time import time
import purestorage

# we'll use one epoch timestamp for each run of this script
epoch_time = int(time())

class Array(object):

    def __init__(self, array_info):
        self.host = array_info['host']
        self.api_token = array_info['api_token']
        self.array = purestorage.FlashArray(self.host, api_token=self.api_token)
        self.name = self.array.get()['array_name']
        self.gather_metrics()
        self.volumes = self._get_volumes()

    def _get_volumes(self):
        """
        Returns list of volumes
        """
        _volumes = []
        for element in self.array.list_volumes():
            volume = Volume(element['name'], self.array)
            _volumes.append(volume)
        return _volumes

    def gather_metrics(self):
        self.info = {}
        _space_metrics = self.array.get(space=True)
        _perf_metrics = self.array.get(action="monitor")
        self.info.update(_space_metrics[0])
        self.info.update(_perf_metrics[0])
        self.percent_used = Metric(int(100 * self.info['total'] / self.info['capacity']), 'percent_used')
        self.system_space = Metric(self.info['system'] / 1024 / 1024 / 1024, 'system_space')  # in GBs
        self.percent_system_space = Metric((100 * (self.info['system'] / float(self.info['capacity']))), 'percent_system_space')
        self.writes_per_sec = Metric(self.info['writes_per_sec'], 'writes_per_sec')
        self.reads_per_sec = Metric(self.info['reads_per_sec'], 'reads_per_sec')
        self.usec_per_write = Metric(self.info['usec_per_write_op'], 'usec_per_write')
        self.usec_per_read = Metric(self.info['usec_per_read_op'], 'usec_per_read')
        self.queue_depth = Metric(self.info['queue_depth'], 'queue_depth')
        self.input_per_sec = Metric(self.info['input_per_sec'], 'input_per_sec')
        self.output_per_sec = Metric(self.info['output_per_sec'], 'output_per_sec')
        self.metrics = [self.percent_used, self.system_space, self.percent_system_space,
                        self.writes_per_sec, self.reads_per_sec, self.usec_per_write,
                        self.usec_per_read, self.queue_depth,self.input_per_sec, self.output_per_sec]

    def close_session(self):
        self.array.invalidate_cookie()


class Volume(object):

    def __init__(self, vol_name, array):
        self.array = array
        self.name = vol_name
        self.get_metrics()

    def get_metrics(self):
        self.info = {}
        _space_metrics = self.array.get_volume(self.name,space=True)
        _perf_metrics = self.array.get_volume(self.name,action="monitor")
        self.info.update(_space_metrics)
        self.info.update(_perf_metrics[0])
        # store total space and space used as GB
        self.total_space = int(self.info['size']) / 1024 / 1024 / 1024
        self.space_used = int(self.info['total']) / 1024 / 1024 / 1024
        self.percent_used = Metric(int(100 * (float(self.space_used) / self.total_space)), 'percent_used')
        self.writes_per_sec = Metric(self.info['writes_per_sec'], 'writes_per_sec')
        self.reads_per_sec = Metric(self.info['reads_per_sec'], 'reads_per_sec')
        # microseconds ( 1 million = 1 sec )
        self.usec_per_write = Metric(self.info['usec_per_write_op'], 'usec_per_write')
        self.usec_per_read = Metric(self.info['usec_per_read_op'], 'usec_per_read')
        self.input_per_sec = Metric(self.info['input_per_sec'], 'input_per_sec')
        self.output_per_sec = Metric(self.info['output_per_sec'], 'output_per_sec')
        self.metrics = [self.percent_used, self.writes_per_sec, self.reads_per_sec,
                        self.usec_per_read, self.usec_per_write, self.input_per_sec,
                        self.output_per_sec]

class Metric(object):

    def __init__(self, value, name):
        self.val = value
        self.name = name

def main():
    pure1_info = { "host": "172.18.16.241", "api_token": "020b4545-012e-bf3c-2a2b-d888d632fb9a"}
    pure2_info = { "host": "172.18.16.244", "api_token": "1a101183-9a8d-ddbb-1bff-da609e82b0f8"}

    for element in [pure1_info, pure2_info]:
        array = Array(element)
        for metric in array.metrics:
            print "{0}.array.{1} {2} {3}".format(array.name, metric.name, metric.val, epoch_time)
        for volume in array.volumes:
            for metric in volume.metrics:
                print "{0}.array.{1}.volume.{2} {3} {4}".format(array.name, volume.name,
                                                                    metric.name, metric.val, epoch_time)
        array.close_session()

if __name__ == '__main__':
    main()
