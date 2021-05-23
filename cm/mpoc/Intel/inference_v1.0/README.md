# MLPerf Benchmarking for Inference Models
- To have benchmarking for each of Models, please clone Inference_results_v1.0 repo
- Setup each model environment on your Test unit or you can create container images on top of Test Unit as well. To have container images create, please refers to below section "To create baseline Ubuntu 20.04"
- Check carefully when modify any of files required from any models' step give from repo. e.g. <this/repo>

## To create baseline Ubuntu container images
- goto docker directory and run docker build command line

## To use Anaconda python virtual environment for benchmarking
- Please install Anaconda Tools to system with script: bash Anaconda_install.sh
- Anaconda_install.sh file can get from <this-repo>/cm/mpoc/Intel directory
- Re-source session envrionment to enable Conda utility: source /etc/environment.

## To install OpenVino Toolkits on top of any of container images
- goto openvino directory
