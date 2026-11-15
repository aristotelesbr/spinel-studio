# The CoreGraphics C functions that draw a PDF page into pixels, used to
# rasterize macOS's own cursor files.
module CoreGraphics
  ffi_cflags "-framework ApplicationServices"

  ffi_func :CFURLCreateFromFileSystemRepresentation, [:ptr, :str, :long, :bool], :ptr
  ffi_func :CFRelease, [:ptr], :void
  ffi_func :CGPDFDocumentCreateWithURL, [:ptr], :ptr
  ffi_func :CGPDFDocumentGetPage, [:ptr, :size_t], :ptr
  ffi_func :CGPDFDocumentRelease, [:ptr], :void
  ffi_func :CGColorSpaceCreateDeviceRGB, [], :ptr
  ffi_func :CGColorSpaceRelease, [:ptr], :void
  ffi_func :CGBitmapContextCreate, [:ptr, :size_t, :size_t, :size_t, :size_t, :ptr, :uint32], :ptr
  ffi_func :CGContextRelease, [:ptr], :void
  ffi_func :CGContextScaleCTM, [:ptr, :double, :double], :void
  ffi_func :CGColorCreateGenericRGB, [:double, :double, :double, :double], :ptr
  ffi_func :CGColorRelease, [:ptr], :void
  # CGSize is two doubles, which arm64 passes like two double arguments.
  ffi_func :CGContextSetShadowWithColor, [:ptr, :double, :double, :double, :ptr], :void
  ffi_func :CGContextDrawPDFPage, [:ptr, :ptr], :void

  PREMULTIPLIED_BGRA = 0x2002   # kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
end
