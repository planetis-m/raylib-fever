
type
  TraceLogCallback* = proc (logLevel: TraceLogLevel; text: string) {.nimcall.} ## Logging: Redirect trace log messages

var
  traceLogCallback: TraceLogCallback # TraceLog callback function pointer

proc wrapperTraceLogCallback(logLevel: int32; text: cstring; args: va_list) {.cdecl.} =
  var buf = newString(128)
  vsprintf(buf.cstring, text, args)
  traceLogCallback(logLevel.TraceLogLevel, buf)

proc setTraceLogCallback*(callback: TraceLogCallback) =
  ## Set custom trace log
  traceLogCallback = callback
  setTraceLogCallbackPriv(wrapperTraceLogCallback)

proc getMonitorName*(monitor: int32): string {.inline.} =
  ## Get the human-readable, UTF-8 encoded name of the primary monitor
  result = $getMonitorNamePriv(monitor)

proc getClipboardText*(): string {.inline.} =
  ## Get clipboard text content
  result = $getClipboardTextPriv()

proc getDroppedFiles*(): seq[string] =
  ## Get dropped files names (memory should be freed)
  var count = 0'i32
  let dropfiles = getDroppedFilesPriv(count.addr)
  result = cstringArrayToSeq(dropfiles, count)

proc getGamepadName*(gamepad: int32): string {.inline.} =
  ## Get gamepad internal name id
  result = $getGamepadNamePriv(gamepad)

proc loadModelAnimations*(fileName: string): seq[ModelAnimation] =
  ## Load model animations from file
  var len = 0'u32
  let data = loadModelAnimationsPriv(fileName.cstring, len.addr)
  if len <= 0:
    raise newException(IOError, "No model animations loaded from " & filename)
  result = newSeq[ModelAnimation](len.int)
  copyMem(result[0].addr, data, len.int * sizeof(ModelAnimation))
  #for i in 0..<len.int:
    #result[i] = data[i]
  memFree(data)

proc loadWaveSamples*(wave: Wave): seq[float32] =
  ## Load samples data from wave as a floats array
  let data = loadWaveSamplesPriv(wave)
  let len = int(wave.frameCount * wave.channels)
  result = newSeq[float32](len)
  copyMem(result[0].addr, data, len * sizeof(float32))
  memFree(data)

proc loadImageColors*(image: Image): seq[Color] =
  ## Load color data from image as a Color array (RGBA - 32bit)
  let data = loadImageColorsPriv(image)
  let len = int(image.width * image.height)
  result = newSeq[Color](len)
  copyMem(result[0].addr, data, len * sizeof(Color))
  memFree(data)

proc loadImagePalette*(image: Image, maxPaletteSize: int32): seq[Color] =
  ## Load colors palette from image as a Color array (RGBA - 32bit)
  var len = 0'i32
  let data = loadImagePalettePriv(image, maxPaletteSize, len.addr)
  result = newSeq[Color](len.int)
  copyMem(result[0].addr, data, len.int * sizeof(Color))
  memFree(data)

proc loadFontData*(fileData: openarray[uint8], fontSize: int32, fontChars: openarray[int32], `type`: FontType): seq[GlyphInfo] =
  ## Load font data for further use
  let data = loadFontDataPriv(cast[ptr UncheckedArray[uint8]](fileData), fileData.len.int32,
      fontSize, cast[ptr UncheckedArray[int32]](fontChars), fontChars.len.int32, `type`)
  result = newSeq[GlyphInfo](fontChars.len)
  copyMem(result[0].addr, data, fontChars.len * sizeof(GlyphInfo))
  memFree(data)

proc loadMaterials*(fileName: string): seq[Material] =
  ## Load materials from model file
  var len = 0'i32
  let data = loadMaterialsPriv(fileName.cstring, len.addr)
  if len <= 0:
    raise newException(IOError, "No materials loaded from " & filename)
  result = newSeq[Material](len.int)
  copyMem(result[0].addr, data, len.int * sizeof(Material))
  #for i in 0..<len.int:
    #result[i] = data[i]
  memFree(data)

proc drawLineStrip*(points: openarray[Vector2], color: Color) {.inline.} =
  ## Draw lines sequence
  drawLineStripPriv(cast[ptr UncheckedArray[Vector2]](points), points.len.int32, color)

proc drawTriangleFan*(points: openarray[Vector2], color: Color) =
  ## Draw a triangle fan defined by points (first vertex is the center)
  drawTriangleFanPriv(cast[ptr UncheckedArray[Vector2]](points), points.len.int32, color)

proc drawTriangleStrip*(points: openarray[Vector2], color: Color) =
  ## Draw a triangle strip defined by points
  drawTriangleStripPriv(cast[ptr UncheckedArray[Vector2]](points), points.len.int32, color)

proc loadImageFromMemory*(fileType: string, fileData: openarray[uint8]): Image =
  ## Load image from memory buffer, fileType refers to extension: i.e. '.png'
  result = loadImageFromMemoryPriv(fileType.cstring, cast[ptr UncheckedArray[uint8]](fileData), fileData.len.int32)

proc drawTexturePoly*(texture: Texture2D, center: Vector2, points: openarray[Vector2], texcoords: openarray[Vector2], tint: Color) =
  ## Draw a textured polygon
  drawTexturePolyPriv(texture, center, cast[ptr UncheckedArray[Vector2]](points), cast[ptr UncheckedArray[Vector2]](texcoords), points.len.int32, tint)

proc loadFontEx*(fileName: string, fontSize: int32, fontChars: openarray[int32]): Font =
  ## Load font from file with extended parameters, use an empty array for fontChars to load the default character set
  result = loadFontExPriv(fileName.cstring, fontSize,
      if fontChars.len == 0: nil else: cast[ptr UncheckedArray[int32]](fontChars), fontChars.len.int32)

proc loadFontFromMemory*(fileType: string, fileData: openarray[uint8], fontSize: int32, fontChars: openarray[int32]): Font =
  ## Load font from memory buffer, fileType refers to extension: i.e. '.ttf'
  result = loadFontFromMemoryPriv(fileType.cstring,
      cast[ptr UncheckedArray[uint8]](fileData), fileData.len.int32, fontSize,
      cast[ptr UncheckedArray[int32]](fontChars), fontChars.len.int32)

proc genImageFontAtlas*(chars: openarray[GlyphInfo], recs: var seq[Rectangle], fontSize: int32, padding: int32, packMethod: int32): Image =
  ## Generate image font atlas using chars info
  var data: ptr UncheckedArray[Rectangle] = nil
  result = genImageFontAtlasPriv(cast[ptr UncheckedArray[GlyphInfo]](chars), data.addr, chars.len.int32, fontSize, padding, packMethod)
  recs = newSeq[Rectangle](chars.len)
  copyMem(recs[0].addr, data, chars.len * sizeof(Rectangle))
  #for i in 0..<len.int:
    #result[i] = data[i]
  memFree(data)

proc drawTriangleStrip3D*(points: openarray[Vector3], color: Color) =
  ## Draw a triangle strip defined by points
  drawTriangleStrip3DPriv(cast[ptr UncheckedArray[Vector3]](points), points.len.int32, color)

proc drawMeshInstanced*(mesh: Mesh, material: Material, transforms: openarray[Matrix]) =
  ## Draw multiple mesh instances with material and different transforms
  drawMeshInstancedPriv(mesh, material, cast[ptr UncheckedArray[Matrix]](transforms), transforms.len.int32)

proc loadWaveFromMemory*(fileType: string, fileData: openarray[uint8]): Wave =
  ## Load wave from memory buffer, fileType refers to extension: i.e. '.wav'
  loadWaveFromMemoryPriv(fileType.cstring, cast[ptr UncheckedArray[uint8]](fileData), fileData.len.int32)

proc loadMusicStreamFromMemory*(fileType: string, data: openarray[uint8]): Music =
  ## Load music stream from data
  loadMusicStreamFromMemoryPriv(fileType.cstring, cast[ptr UncheckedArray[uint8]](data), data.len.int32)

proc drawTextCodepoints*(font: Font, codepoints: openarray[int32], position: Vector2,
    fontSize: float32, spacing: float32, tint: Color) =
  drawTextCodepointsPriv(font, cast[ptr UncheckedArray[uint8]](codepoints),
      codepoints.len.int32, position, spacing, tint)
