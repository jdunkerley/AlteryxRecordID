/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 * @param json Configuration
 */
Alteryx.Gui.BeforeLoad = (manager, AlteryxDataItems, json) => {
  const dataFieldNameItem = new AlteryxDataItems.SimpleString('FieldName', {})
  dataFieldNameItem.setValue('RecordID')
  manager.addDataItem(dataFieldNameItem)
  manager.bindDataItemToWidget(dataFieldNameItem, 'dataFieldName')

  const dataLastColumnItem = new AlteryxDataItems.SimpleBool('LastColumn', {})
  dataLastColumnItem.setValue(true)
  manager.addDataItem(dataLastColumnItem)
  manager.bindDataItemToWidget(dataLastColumnItem, 'dataLastColumn')

  const dataFieldTypeItem = new AlteryxDataItems.StringSelector('FieldType', {
    optionList: [
      'Byte',
      'Int16',
      'Int32',
      'Int64',
      'String',
      'WString',
      'V_String',
      'V_WString'
    ].map(a => { return {label: a, value: a} })
  })
  dataFieldTypeItem.setValue('Int64')
  manager.addDataItem(dataFieldTypeItem)
  manager.bindDataItemToWidget(dataFieldTypeItem, 'dataFieldType')
}

/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 */
Alteryx.Gui.AfterLoad = (manager, AlteryxDataItems) => {
}

/**
 * Reformat the JSON to the style we need
 * @param json Configuration
 */
Alteryx.Gui.BeforeGetConfiguration = (json) => {
  return json
}

/**
 * Set the tool's default annotation on the canvas.
 * @param manager The data manager.
 * @returns {string}
 */
Alteryx.Gui.Annotation = (manager) => ''
