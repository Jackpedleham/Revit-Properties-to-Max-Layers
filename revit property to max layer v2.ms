-- Global variable to hold collected properties
global collectedProperties

-- Function to collect all unique property names from scene objects
fn collectUniquePropertyNames = (
    local uniqueProps = #()
    for obj in objects do (
        local userPropsString = getUserPropBuffer obj
        if userPropsString != undefined and userPropsString != "" do (
            local lines = filterString userPropsString "\n"
            for line in lines do (
                local propName = trimLeft (trimRight ((filterString line "=")[1]))
                if propName != "" and findItem uniqueProps propName == 0 do (
                    append uniqueProps propName
                )
            )
        )
    )
    uniqueProps
)


-- Sanitize the string to make it a valid layer name
fn sanitizeStringForLayerName objname =
(
    local invalidCharsPattern = "[#,:\\[\\]*?<>|]" -- Regular expression pattern for invalid characters
    substituteString objname invalidCharsPattern "_" -- Replace all occurrences of invalid characters with "_"
)

-- Function to assign objects to layers based on a selected property
fn assignObjectsToLayersByProperty propertyName =
(
    local countProcessed = 0
    local countSkipped = 0
    for obj in objects do (
        local propValue = getUserProp obj propertyName -- Corrected function to retrieve the user property value
        if propValue != undefined then (
            -- Sanitize property value for use in layer name
            propValue = sanitizeStringForLayerName (propValue as string)
            local layerName = sanitizeStringForLayerName (propValue)

            -- Attempt to retrieve the layer, or create a new one if it doesn't exist
            local layer = LayerManager.getLayerFromName layerName
            if layer == undefined do (
                layer = LayerManager.newLayerFromName layerName
            )

            -- Add the object to the layer
            layer.addNode obj
            countProcessed += 1
        ) else (
            format "Skipping object: %\n" obj.name
            countSkipped += 1
        )
    )
    format "Total Objects Processed: %\n" countProcessed
    format "Total Objects Skipped: %\n" countSkipped
)

-- Rollout to display the UI for property selection
rollout propSelectionRollout "Layers"
(

    
	
	button btnAssign "Generate Layers" pos:[5,81] width:94 height:24 align:#left enabled:false
	label lblLayerCount "Layers: 0" pos:[5,60] width:95 height:18 align:#left
	dropDownList ddlProperties "Properties:" pos:[5,14] width:99 height:40 align:#left items:collectedProperties

   fn countLayersByProperty propertyName =
(
    local layerNames = #()
    for obj in objects do (
        local propValue = getUserProp obj propertyName
        if propValue != undefined then (
            propValue = sanitizeStringForLayerName (propValue as string)
            appendIfUnique layerNames propValue
        )
    )
    layerNames.count
)
    on ddlProperties selected index do
    (
        if index > 0 then
        (
            local selectedProperty = ddlProperties.items[index]
            local layerCount = countLayersByProperty selectedProperty
            lblLayerCount.text = "Layers: " + layerCount as string
            btnAssign.enabled = true
        )
        else
        (
            lblLayerCount.text = "Layers: 0"
            btnAssign.enabled = false
        )
    )

    on btnAssign pressed do
    (
        if ddlProperties.selection > 0 do
        (
            local selectedProperty = ddlProperties.items[ddlProperties.selection]
            assignObjectsToLayersByProperty selectedProperty
            destroyDialog propSelectionRollout
        )
    )
)
-- Main script execution
(
    collectedProperties = collectUniquePropertyNames()
    if collectedProperties.count > 0 then
        createDialog propSelectionRollout 120 120 -- Corrected function to create a dialog
    else
        messagebox "No unique properties found among objects in the scene."
)
