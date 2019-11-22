using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))
products = [
    ExecutableProduct(prefix, "dex", :dex),
    ExecutableProduct(prefix, "grpc-client", :grpcclient),
    ExecutableProduct(prefix, "bcrypt-cli", :bcryptcli),
]

# Download binaries from hosted location
bin_prefix = "https://github.com/tanmaykm/DexBuilder/releases/download/v2.20.0"

# Listing of files generated by BinaryBuilder:
download_info = Dict(
    Linux(:x86_64, libc=:glibc) => ("$bin_prefix/DexBuilder.v2.20.0.x86_64-linux-gnu.tar.gz", "adc389a38b1809ca95fc365a570681ce832c86a33cc8adaf33371817b6f13e93"),
    Linux(:x86_64, libc=:musl) => ("$bin_prefix/DexBuilder.v2.20.0.x86_64-linux-musl.tar.gz", "716ca38f417c277754384f7d768d066e9d99d08da732f477328eeb05f3087ef9"),
)

# Install unsatisfied or updated dependencies:
unsatisfied = any(!satisfied(p; verbose=verbose) for p in products)
dl_info = choose_download(download_info, platform_key_abi())
if dl_info === nothing && unsatisfied
    # If we don't have a compatible .tar.gz to download, complain.
    # Alternatively, you could attempt to install from a separate provider,
    # build from source or something even more ambitious here.
    error("Your platform (\"$(Sys.MACHINE)\", parsed as \"$(triplet(platform_key_abi()))\") is not supported by this package!")
end

# If we have a download, and we are unsatisfied (or the version we're
# trying to install is not itself installed) then load it up!
if unsatisfied || !isinstalled(dl_info...; prefix=prefix)
    # Download and install binaries
    install(dl_info...; prefix=prefix, force=true, verbose=verbose)
end

# Write out a deps.jl file that will contain mappings for our products
write_deps_file(joinpath(@__DIR__, "deps.jl"), products, verbose=verbose)
