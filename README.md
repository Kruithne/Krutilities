Krutilities
--------------
This is a small module for World of Warcraft add-ons intended to streamline the generic creation of frames, textures and font-strings without introducing a large library of unwanted features.

Usage
--------
Everything this module offers is exposed via the global `Krutilities`. Before accessing the functions exposed through this module, it's highly recommended to create a local reference to it.

```lua
local K = Krutilities;
```
> **Note:** It's common practice in Lua development to create local references to things you use more than once from the global scope. The variable name itself is not important, but **K** works well here.

**Creating Frames**

Creating frames can be done easily using the ``Frame`` function, which takes a self-reference along with a constructor table.

```lua
local myFrame = K:Frame({
	name = "MyAddonFrame"
});
```
Without anything extra, this will create a frame named ``MyAddonFrame`` attached to ``UIParent``. Check below for a full list of things you can provide in the constructor table along with defaults for omitted values.

The returned frame will also include three extra helper utility functions: ``SpawnTexture``, ``SpawnText`` and ``SpawnFrame``. These are short-cuts to calling the respective core functions from Krutilities with the frame as the parent by default.

```lua
local childFrame = myFrame:SpawnFrame({
	name = "$parentChildFrame"
});
```
This will create another frame called ``MyAddonFrameChildFrame``, parented to ``MyAddonFrame``.

**Creating Textures**

Using the same format as frames, we can easily create textures using the ``Texture`` function provided by Krutilities. In this example, rather than using the function directly, we'll show-case how the short-cut functions from a frame work.

```lua
local myFrame = K:Frame({
	name = "MyFrame"
});

myFrame:SpawnTexture({
	injectSelf = "tex", -- Allows us to use myFrame.tex to reference this.
	size = 50, -- 50 x 50
	texture = [[Interface\DialogFrame\UI-DialogBox-Gold-Background]],
});
```

Check the constructor reference below to see all parameters that can be provided along with their defaults.

**Creating Text**

Again, using the same format we did for frames and textures, we can easily spawn text using the ``Text`` function. Rather than using the direct method (as seen in the frame demo) or the chain method (as seen in the texturing demo), we're going to use the pass-in method in this example.

```lua
local myFrame = K:Frame({
	name = "MyFrame",
	texts = {
		parentName = "Label", -- MyFrameLabel
		injectSelf = "label", -- Allows access via myFrame.label
		text = "Hello, world!"
	}
});
```
For a more in-depth look at how pass-in  creation works, check out the Recursive Creation section further down in this document.

**Constructor Reference for Frame**

| Parameter  | Type | Description | Default (when omitted) |
| ---------- | ---- | ----------- | ---------------------- |
| parent | frame, string | A frame which the created frame will parent to. Can be a frame reference or string (global lookup). | ``UIParent`` (or the calling frame for ``SpawnFrame``). |
| name | string | Name for the frame. Will be indexed globally using this. Supports ``$parent`` reference. | Automatically generated by the client. |
| parentName | string | Name for the frame, with parent name prepended. Short-cut for ``$parentMyFrameName``. |  |
| type | string | Type of frame, such as ``BUTTON`` or ``FRAME``. | ``FRAME`` |
| inherit | string | Template to use, can be comma-seperated for multiple. |  |
| hidden | bool | If provided, the frame will be hidden initially. | ``false`` |
| strata | string | Sets the frame strata to the value provided. | |
| width | int | Sets the width of the frame. | |
| height | int | Sets the height of the frame. | | 
| size | int, table | Short-cut for width/height. If table, usage is ``{width,height}``. If int, value will be used for both width and height. | |
| injectSelf | string | Inject the created frame into the parent with the given key. If ``injectSelf`` is ``foo`` then ``parent.foo`` will be a reference to the new frame. | |
| points | table | See anchoring reference in this document. | Single basic ``CENTER`` anchor. | |
| setAllPoints | bool | If provided all points will be set to match the parent. | ``false`` |
| backdrop | table | Set the backdrop for the frame. See http://wowprogramming.com/docs/widgets/Frame/SetBackdrop | |
| data | table | Selection of values/references to inject into the frame in a key/value fashion. ``{ test = true }`` will produce ``frame.test; -- true`` | |
| multiLine | bool | Set if this is a multi-line frame. Only works for ``EDITBOX`` frames. | ``false`` |
| autoFocus | bool | Set if this frame should auto-focus. Only works for ``EDITBOX`` frames. | ``false`` |
| frames | table | See recursive creation in this document. | |
| textures | table | See recursive creation in this document. | |
| texts | table | See recursive creation in this document. | |
| scripts | table | Set script handlers for the frame. Each table key is the event, ie ``OnShow``, with the value being the handler function for said event. | |

**Constructor Reference for Textures**

| Parameter  | Type | Description | Default (when omitted) |
| ---------- | ---- | ----------- | ---------------------- |
| parent | frame, string | A frame which the created texture will parent to. Can be a frame reference or string (global lookup). | ``UIParent`` (or the calling frame for ``SpawnTexture``). |
| name | string | Name for the texture. Supports ``$parent`` reference. | Automatically generated by the client. |
| parentName | string | Name for the texture, with parent name prepended. Short-cut for ``$parentMyTextureName``. |  |
| layer | string | Graphic layer to use for this texture. | ``ARTWORK`` |
| inherit | string | Template to use for this texture. | |
| subLevel | int | Graphical sub-level to render this on. Range: -8 to 7. | ``0``
| width | int | Sets the width of the texture. | |
| height | int | Sets the height of the texture. | | 
| size | int, table | Short-cut for width/height. If table, usage is ``{width,height}``. If int, value will be used for both width and height. | |
| injectSelf | string | Inject the created texture into the parent with the given key. If ``injectSelf`` is ``tex`` then ``parent.tex`` will be a reference to the new texture. ||
| tile | bool | If set, the texture will tile both horizontally and vertically. | ``false`` |
| tileX | bool | If set, the texture will tile horizontally. Has no effect if ``tile`` is set. | ``false`` |
| tileY | bool | If set, the texture will tile vertically. Has no effect if ``tile`` is set. | ``false`` |
| texture | string | The texture file to use for this texture. | |
| points | table | See anchoring reference in this document. | All points set. |
| setAllPoints | bool | If set, all points will match the parent. Setting to ``false`` will disable default behavior of ``points``; leaving omitted will not. | ``true`` if ``points`` is omitted, else ``false`` |
| color | table | Specifies vertex colouring. Formats: ``{r: 0, g: 0, b: 0, a: 1}`` or ``{0, 0, 0, 1}``.| Omitted values default to ``0`` (alpha defaults to ``1``).
| texCoord | table | Sets the texture co-ordinates. Format: ``{left,right,top,bottom}``. | ``{0, 1, 0, 1}`` |

**Constructor Reference for Text**

| Parameter  | Type | Description | Default (when omitted) |
| ---------- | ---- | ----------- | ---------------------- |
| parent | frame, string | A frame which the created font-string will parent to. Can be a frame reference or string (global lookup). | ``UIParent`` (or the calling frame for ``SpawnText``). |
| name | string | Name for the font-string. Supports ``$parent`` reference. | Automatically generated by the client. |
| parentName | string | Name for the font-string, with parent name prepended. Short-cut for ``$parentMyLabel``. |  |
| layer | string | Graphic layer to use for this font-string. | ``ARTWORK`` |
| inherit | string | Template to use for this font-string. | |
| width | int | Sets the width of the font-string. | |
| height | int | Sets the height of the font-string. | | 
| size | int, table | Short-cut for width/height. If table, usage is ``{width,height}``. If int, value will be used for both width and height. | |
| injectSelf | string | Inject the created font-string into the parent with the given key. If ``injectSelf`` is ``label`` then ``parent.label`` will be a reference to the new font-string. ||
| text | string | The initial text to display in the font-string. | |
| justifyH | string | Horizontal justify method. ``CENTER``, ``LEFT`` or ``RIGHT`` |
| justifyV | string | Vertical justify method. ``BOTTOM``, ``MIDDLE`` or ``TOP`` |
| maxLines | int | Maximum amount of lines allowed. |
| color | table | Specifies text colour. Formats: ``{r: 0, g: 0, b: 0, a: 1}`` or ``{0, 0, 0, 1}``.| Omitted values default to ``0`` (alpha defaults to ``1``). |
| points | table | See anchoring reference in this document. | Single basic ``CENTER`` point. |

**Anchoring Reference**

Anchoring data can be provided for all three of the primary factory functions in the form of a simple table. If you're providing just one point, the table itself can be an anchoring node with the parameters directly supplied. If you're providing multiple anchors, then each point must be it's own table inside the initial table.

```lua
-- Example: Single anchor point.
local myFrame = K:Frame({
	points = {
		point = "LEFT", -- Defaults to CENTER if omitted.
		relativeTo = SomeOtherFrame, -- Defaults to parent if omitted.
		relativePoint = "RIGHT", -- Defaults to point if omitted.
		x = 50, -- Defaults to 0 if omitted.
		y = -20, -- Defaults to 0 if omitted.
	};
});
```
```lua
-- Example: Multiple anchor points.
local myFrame = K:Frame({
	points = {
		{ point = "LEFT" }, -- With defaults, anchors LEFT to parents LEFT.
		{ point = "RIGHT" }, -- With defaults, anchors RIGHT to parents RIGHT.
	}
});
```

>**Note:** The ``relativeTo`` value must be an actual frame reference; no global-lookup is performed for strings, unlike during frame parenting.

**Recursive Creation**

In addition to the short-cut functions injected into created frames, recursive creation is also possible by providing constructor data for child elements directly into constructor tables.

>**Note**: Recursive creation only works for frames; textures and texts do not support child creation in any format beyond being anchored together.

Frames currently support the ``frames``, ``textures`` and ``texts`` parameters, for which a table must be provided for. If you intend to create just one child, the table itself can be the constructor data for said child. If you intend to create multiple of the same type of child, the table must contain each constructor table as a separate element.

Children created through this method can contain everything listed in the above references with the ``parent`` defaulting to the encasing frame rather than ``UIParent``. This means it is perfectly legal to have a child frame containing another child frame, recurring downwards in a tree.

Extra Utilities
-------------------
Beyond the core functionality of Krutilities, some extra utility functions are provided. 

**CloneTable**

Clones the provided table, creating a duplicate of it. The behavior of the cloning can be controlled by the ``deep`` parameter.
>**Syntax**: K.CloneTable(*tbl*, *deep*);

| Parameter  | Type | Description | Default |
| ---------- | ---- | ----------- | ------- |
| tbl | table | The table to clone. | *Required*
| deep | bool | If true, will produce a deep clone. | ``false``

>**Deep Cloning**: A deep clone will inspect every element down the tree and clone any tables found in the keys and/or values. In a non-deep clone, nested tables will be copied by reference. Functions and userdata are always copied by reference.

**Dump**

Invokes the behavior of the ``/dump`` command included in ``Blizzard_DebugTools`` on the provided reference or value. Useful for inspecting variables during debugging.
>**Syntax**: K.Dump(*obj*);

| Parameter  | Type | Description | Default |
| ---------- | ---- | ----------- | ------- |
| obj | anything | Object or value to dump. | *Required*

**EventHandler**

A quick-and-dirty short-cut for creating an event handler. This is aimed to save some time when creating smaller add-ons; if you're creating a larger, more intensive add-on, creating a tailored event handler would be more ideal.

>**Syntax**: K.EventHandler(*addon*, *events*);

| Parameter  | Type | Description | Default |
| ---------- | ---- | ----------- | ------- |
| addon | table | Object containing the functions to call. | *Required*
| events | table | Key/value table of events mapped to function names. | *Required*

```lua
-- Example: EventHandler usage.
local K = Krutilities;
local myAddon = {
	onAddonLoaded = function(addonName)
		-- Do some things.
	end
};

K.EventHandler(myAddon, {
	["ADDON_LOADED"] = "onAddonLoaded"
});
```

Contributing, Ideas, Feedback
-----------------------------------------
If you have any ideas or feedback, feel free to submit a ticket to this repository. This projected was created for personal use, but can always be improved for other people's own usage.

Are you handy with Lua? Feel free to tinker and submit a pull request with any improvements or additions you've made. Please be mindful of the coding practices employed and keep things consistent.