"""hsc file handling."""

load(":path_utils.bzl",
  "declare_compiled",
  "mk_name",
)

load(":tools.bzl", "get_hsc2hs")

def hsc_to_hs(ctx):
  """Process all hsc files into Haskell source files.

  Args:
    ctx: Rule context.

  Returns:
    list of File: New Haskell source files to use.
  """
  sources = []
  for f in ctx.files.srcs:
    if f.extension == "hsc":
      sources.append(_process_hsc_file(ctx, f))
    else:
      sources.append(f)
  return sources

def _process_hsc_file(ctx, hsc_file):
  """Process a single hsc file.

  Args:
    ctx: Rule context.
    hsc_file: hsc file to process.

  Returns:
    File: Haskell source file created by processing hsc_file.
  """
  hsc_output_dir = ctx.actions.declare_directory(mk_name(ctx, "hsc_processed"))

  # Output a Haskell source file.
  hs_out = declare_compiled(ctx, hsc_file, ".hs", directory=hsc_output_dir)
  # Make all external dependency files available.
  external_files = depset([f for dep in ctx.attr.external_deps
                             for f in dep.files])
  # Add all directories of external dependencies to include dirs.
  include_directories = depset([f.dirname for f in external_files.to_list()])

  args = ctx.actions.args()
  args.add([hsc_file, "-o", hs_out])
  for include_dir in include_directories.to_list():
    args.add(["-I", include_dir])

  ctx.actions.run(
    inputs = depset(transitive = [external_files, depset([hsc_file])]),
    outputs = [hs_out, hsc_output_dir],
    use_default_shell_env = True,
    progress_message = "hsc2hs {0}".format(hsc_file.basename),
    executable = get_hsc2hs(ctx),
    arguments = [args],
  )
  return hs_out