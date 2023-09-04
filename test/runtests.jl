# Work around JuliaLang/Pkg.jl#2500
if VERSION < v"1.8-"
    test_project = first(Base.load_path())
    preferences_file = "LocalPreferences.toml"
    test_preferences_file = joinpath(dirname(test_project), "LocalPreferences.toml")
    if isfile(preferences_file) && !isfile(test_preferences_file)
        cp(preferences_file, test_preferences_file)
    end
end

using LLVM

if Base.JLOptions().debug_level < 2
    @warn "It is recommended to run the LLVM.jl test suite with -g2"
end

using InteractiveUtils
@info "System information:\n" * sprint(io->versioninfo(io))

worker_init_expr = quote
    using LLVM

    # HACK: if a test throws within a Context() do block, displaying the LLVM value may
    #       crash because the context has been disposed already. avoid that by disabling
    #       `dispose`, and only have it pop the context off the stack (but not destroy it).
    LLVM.dispose(ctx::Context) = LLVM.deactivate(ctx)
end

using ReTestItems
runtests(LLVM; worker_init_expr, nworkers=min(Sys.CPU_THREADS,4), nworker_threads=1)
