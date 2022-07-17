// Parameters
param location string = resourceGroup().location
param logicAppName string

var logicAppDefinition = json(loadTextContent('definition.json'))

// // Basic logic app
// Used to pull in just the definition, But not needed anymore
// resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
//   name: logicAppName
//   location: location
//   properties: {
//     state: 'Enabled'
//     definition: logicAppDefinition
//   }
// }

resource logicapptype 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      triggers: {
        http_request: {
          type: 'request'
          kind: 'http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                Url: {
                  type: 'string'
                  accesstoken: {
                    type: 'string'
                  }
                }
              }
              required: [
                'Url'
                'accesstoken'
              ]
            }
          }
          operationOptions: 'EnableSchemaValidation'
        }
      }
      actions: {
        'Initialize_variable_-_Graph_Return': {
          inputs: {
            variables: [ {
                name: 'GraphReturn'
                type: 'array'
              } ]
          }
          runafter: {}
          type: 'InitializeVariable'
        }
        'Initialize_variable_-_NextLink': {
          inputs: {
            variables: [ {
                name: 'nextlink'
                type: 'string'
              } ]
          }
          runafter: {

          }
          type: 'InitializeVariable'
        }
        'Initialize_variable_-_AccessToken': {
          inputs: {
            variables: [ {
                name: 'AccessToken'
                type: 'string'
                value: '@{string(triggerBody()?[\'accesstoken\'])}'
              } ]
          }
          runafter: {}
          type: 'InitializeVariable'
        }
        'HTTP_-_Initial_Request': {
          inputs: {
            headers: {
              Authorization: 'bearer @{variables(\'AccessToken\')}'
              'content-type': 'application/json'
            }
            method: 'GET'
            uri: '@triggerBody()?[\'Url\']'
          }
          runafter: {
            'Initialize_variable_-_AccessToken': [
              'Succeeded'
            ]
            'Initialize_variable_-_Graph_Return': [
              'Succeeded'
            ]
            'Initialize_variable_-_NextLink': [
              'Succeeded'
            ]
          }
          type: 'http'
        }
        'Parse_JSON_-_Initial_Response_(for_NextLink)': {
          inputs: {
            content: '@body(\'HTTP_-_Initial_Request\')'
            schema: {
              properties: {
                '@@odata.context': {
                  type: 'string'
                }
                '@@odata.nextLink': {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
          runAfter: {
            'HTTP_-_Initial_Request': [
              'Succeeded'
            ]
          }
          type: 'ParseJson'
        }
        'Append_to_array_variable_-_GraphReturn': {
          inputs: {
              name: 'GraphReturn'
              value: '@body(\'HTTP_-_Initial_Request\')'
          }
          runAfter: {
              'Parse_JSON_-_Initial_Response_(for_NextLink)': [
                  'Succeeded'
              ]
          }
          type: 'AppendToArrayVariable'
      }
      'Condition_-_If_response_contains_@odata.nextlink': {
        actions: {
            'Response_-_NextLink': {
                inputs: {
                    body: '@variables(\'GraphReturn\')'
                    statusCode: 200
                }
                kind: 'http'
                runAfter: {
                    'Until_-_NextLink_is_Blank': [
                        'Succeeded'
                    ]
                }
                type: 'Response'
            }
            'Set_variable_-_NextLink_for_Next_Call': {
                inputs: {
                    name: 'nextlink'
                    value: '@body(\'Parse_JSON_-_Initial_Response_(for_NextLink)\')?[\'@odata.nextLink\']'
                }
                runAfter: {}
                type: 'SetVariable'
            }
            'Until_-_NextLink_is_Blank': {
                actions: {
                    'Compose_-_Union_GraphReturn_and_the_additional_data_from_NextLink_Call': {
                        inputs: '@union(variables(\'GraphReturn\'),body(\'HTTP__-_Get_NextLink_Data\')[\'value\'])'
                        runAfter: {
                            'Parse_JSON_-_NextLink_Response_(for_NextLink)': [
                                'Succeeded'
                            ]
                        }
                        type: 'Compose'
                    }
                    'Condition_-_If_@Odata.nextlink_is_not_blank_(Until_Loop)': {
                        actions: {
                            'Set_variable_-_NextLink_to_Blank': {
                                inputs: {
                                    name: 'nextlink'
                                    value: '\'\''
                                }
                                runAfter: {}
                                type: 'SetVariable'
                            }
                        }
                        else: {
                            actions: {
                                'Set_variable_-_NextLink_to_@odata.nextlink': {
                                    inputs: {
                                        name: 'nextlink'
                                        value: '@body(\'Parse_JSON_-_NextLink_Response_(for_NextLink)\')?[\'@odata.nextLink\']'
                                    }
                                    runAfter: {}
                                    type: 'SetVariable'
                                }
                            }
                        }
                        expression: {
                            and: [
                                {
                                    equals: [
                                        '@body(\'Parse_JSON_-_NextLink_Response_(for_NextLink)\')?[\'@odata.nextLink\']'
                                        ''
                                    ]
                                }
                            ]
                        }
                        runAfter: {
                            'Set_variable_-_GraphReturn_from_Compose_Output': [
                                'Succeeded'
                            ]
                        }
                        type: 'If'
                    }
                    'HTTP__-_Get_NextLink_Data': {
                        inputs: {
                            headers: {
                                Authorization: 'bearer @{triggerBody()?[\'accesstoken\']}'
                                'content-type': 'application/json'
                            }
                            method: 'GET'
                            uri: '@variables(\'nextlink\')'
                        }
                        runAfter: {}
                        type: 'Http'
                    }
                    'Parse_JSON_-_NextLink_Response_(for_NextLink)': {
                        inputs: {
                            content: '@body(\'HTTP__-_Get_NextLink_Data\')'
                            schema: {
                                properties: {
                                    '@@odata.context': {
                                        type: 'string'
                                    }
                                    '@@odata.nextLink': {
                                        type: 'string'
                                    }
                                }
                                type: 'object'
                            }
                        }
                        runAfter: {
                            'HTTP__-_Get_NextLink_Data': [
                                'Succeeded'
                            ]
                        }
                        type: 'ParseJson'
                    }
                    'Set_variable_-_GraphReturn_from_Compose_Output': {
                        inputs: {
                            name: 'GraphReturn'
                            value: '@outputs(\'Compose_-_Union_GraphReturn_and_the_additional_data_from_NextLink_Call\')'
                        }
                        runAfter: {
                            'Compose_-_Union_GraphReturn_and_the_additional_data_from_NextLink_Call': [
                                'Succeeded'
                            ]
                        }
                        type: 'SetVariable'
                    }
                }
                expression: '@equals(variables(\'nextlink\'), \'\')'
                limit: {
                    count: 60
                    timeout: 'PT1H'
                }
                runAfter: {
                    'Set_variable_-_NextLink_for_Next_Call': [
                        'Succeeded'
                    ]
                }
                type: 'Until'
            }
        }
        else: {
            actions: {
                'Response_-_No_NextLink': {
                    inputs: {
                        body: '@variables(\'GraphReturn\')'
                        statusCode: 200
                    }
                    kind: 'Http'
                    runAfter: {}
                    type: 'Response'
                }
            }
        }
        expression: {
            and: [
                {
                    not: {
                        equals: [
                            '@body(\'Parse_JSON_-_Initial_Response_(for_NextLink)\')?[\'@odata.nextLink\']'
                            ''
                        ]
                    }
                }
                {
                    not: {
                        equals: [
                            '@body(\'Parse_JSON_-_Initial_Response_(for_NextLink)\')?[\'@odata.nextLink\']'
                            '@null'
                        ]
                    }
                }
            ]
        }
        runAfter: {
            'Append_to_array_variable_-_GraphReturn': [
                'Succeeded'
            ]
        }
        type: 'If'
    }
      }
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
    }
    parameters: {}
  }
}

//Read ME: https://docs.microsoft.com/en-gb/azure/azure-resource-manager/bicep/linter-rule-outputs-should-not-contain-secrets
#disable-next-line outputs-should-not-contain-secrets // Does not contain a password
output logicAppURL string = listCallbackURL('${logicapptype.id}/triggers/http_request', '2017-07-01').value
