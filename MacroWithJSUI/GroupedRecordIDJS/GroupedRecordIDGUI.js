/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 * @param json Configuration
 */
Alteryx.GUI.BeforeLoad = (manager, dataItems, json) => {
}

/**
 * Specify actions that will take place before the tool's configuration is loaded into the manager.
 * @param manager The data manager.
 * @param AlteryxDataItems The data items in use on this page.
 */
Alteryx.GUI.AfterLoad = (manager, AlteryxDataItems) => {
}

/**
 * Reformat the JSON to the style we need
 * @param json Configuration
 */
Alteryx.GUI.BeforeGetConfiguration: (json) =>  {
    return json
}

/**
 * Set the tool's default annotation on the canvas.
 * @param manager The data manager.
 * @returns {string}
 */
Alteryx.GUI.Annotation = (manager) => ""
