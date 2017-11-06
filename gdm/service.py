# Copyright 2016 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Create configuration to deploy Kubernetes resources."""


def GenerateConfig(context):
  """Generate YAML resource configuration."""

  cluster_type = ''.join([context.env['project'], '/',
                          context.properties['clusterType']])
  name_prefix = context.env['deployment'] + '-' + context.env['name']
  namespace = context.properties['namespace']

  resources = [{
      'name': name_prefix,
      'type': cluster_type + ':' + '/api/v1/namespaces/{namespace}/services',
      'properties': {
          'apiVersion': 'v1',
          'kind': 'Service',
          'namespace': namespace,
          'metadata': {
              'name': name_prefix
          },
          'spec': {
              'ports': [{
                  'port': 80,
                  'targetPort': 8081,
                  'protocol': 'TCP',
                  'name': 'http'
              }],
              'selector': {
                  'app': 'helloworld'
              }
          }
      }
  }, {
      'name': name_prefix + "dep",
      'type': cluster_type + ':' + '/api/apps/v1beta1/namespaces/{namespace}/deployments',
      'properties': {
          'apiVersion': 'apps/v1beta1',
          'kind': 'Deployment',
          'namespace': namespace,
          'metadata': {
              'name': 'helloworld'
          },
          'spec': {
              'replicas': 2,
              'template': {
                  'metadata': {
                      'labels': {
                          'app': 'helloworld'
                      }
                  },
                  'spec': {
                      'containers': [
                          {
                              'name': 'helloworld',
                              'image': context.properties['image'],
                              'ports': [{
                                  'containerPort': 8080
                              }]
                          }, {
                              'name': 'esp',
                              'image': 'gcr.io/endpoints-release/endpoints-runtime:1',
                              'args' :[
                                  '-p', '8081',
                                  '-a', '127.0.0.1:8080',
                                  '-s', 'helloworld-api.endpoints.%s.cloud.goog'%context.env['project'],
                                  '-v', context.properties['service-config'],
                                  '-z', 'healthz',
                              ],
                              'readinessProbe': {
                                  'path': '/healthz',
                                  'port': 8081
                              },
                              'ports': [{
                                  'containerPort': 8081
                              }]
                          }
                      ]
                  }
              }
          }
      }
  }]

  return {'resources': resources}
