#include "Dataset.h"
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <Eigen/Dense>
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>
#include <pcl/io/ply_io.h>
#include <pcl/io/obj_io.h>
#include <boost/format.hpp>
#include <pcl/filters/crop_box.h>
#include <pcl/common/io.h>
#include <pcl/sample_consensus/sac_model_plane.h>
#include <pcl/search/kdtree.h>
#include <filesystem>

using namespace pcl;
using namespace std;
using namespace boost::filesystem;
std::string Dataset::out_dir =  "";
bool Dataset::just_save_files = false;

int list_files(std::string path, std::vector<std::string> &fnames)
{
    directory_iterator end_itr;
    for (directory_iterator itr(path); itr != end_itr; ++itr)
    {
        if (is_regular_file(itr->path())) {
            size_t lastindex = itr->path().filename().string().find_last_of(".");
            fnames.push_back(itr->path().filename().string().substr(0, lastindex));
        }
    }
    std::sort(fnames.begin(), fnames.end());
}


void Dataset::load_ply_file(const std::string& las_path, PointCloud3D::Ptr& out_pcl) {
    pcl::PLYReader Reader;
    out_pcl = PointCloud3D::Ptr(new PointCloud3D);
    Reader.read(las_path, *out_pcl);
}

void Dataset::load_las_file(const std::string& las_path, PointCloud3D::Ptr& out_pcl) {
    std::ifstream ifs;

    //std::cout<< "Loading las file: " << las_path << std::endl;
    ifs.open(las_path, std::ios::in | std::ios::binary);
    liblas::ReaderFactory f;
    liblas::Reader reader(ifs);
    liblas::Header const& header = reader.GetHeader();
    //std::cout << "Signature: " << header.GetFileSignature() << " Points count: " << header.GetPointRecordsCount() << '\n';

    out_pcl = PointCloud3D::Ptr(new PointCloud3D);
    out_pcl->points.clear();
    out_pcl->width = header.GetPointRecordsCount() ;
    out_pcl->height = 1;
    out_pcl->points.resize(out_pcl->width*out_pcl->height);

    std::vector<liblas::Color> colors;
    int index = 0;
    float max_val=0;
    while (reader.ReadNextPoint())
    {
        liblas::Point const& p = reader.GetPoint();
        out_pcl->points[index].x = p.GetX();//*header.GetScaleX()+ header.GetOffsetX();
        out_pcl->points[index].y = p.GetY();//*header.GetScaleY()+ header.GetOffsetY();
        out_pcl->points[index].z = p.GetZ();//*header.GetScaleZ()+ header.GetOffsetZ();

        colors.push_back(p.GetColor());
        if( colors[index].GetRed() > max_val ) max_val = colors[index].GetRed();
        if( colors[index].GetGreen() > max_val ) max_val = colors[index].GetGreen();
        if( colors[index].GetBlue() > max_val ) max_val = colors[index].GetBlue();
        index++;
    }
    for(int i = 0; i < out_pcl->size(); i++){
        out_pcl->points[i].r = static_cast<std::uint8_t>( (colors[i].GetRed() / max_val)*255 );
        out_pcl->points[i].g = static_cast<std::uint8_t>( (colors[i].GetGreen() / max_val)*255 );
        out_pcl->points[i].b = static_cast<std::uint8_t>( (colors[i].GetBlue() / max_val)*255 );
        //std::cout << "R: " << xyz_rgb_2016->points[i].r << " G: " << xyz_rgb_2016->points[i].g << " B: "<< xyz_rgb_2016->points[i].b << std::endl;
    }
    //pcl::io::savePLYFile(las_path.substr(0, las_path.size()-4) + ".ply", *out_pcl);
    ifs.close();

    if(just_save_files)
        pcl::io::savePLYFile(las_path.substr(0, las_path.size()-4) + "_original.ply", *out_pcl);
    //pcl::io::saveOBJFile(las_path.substr(0, las_path.size()-4) + ".obj",  out_pcl);
}

void Dataset::load_label_from_csv(string csv_path) {
    std::ifstream csv_ifs;
    std::string line;
    csv_ifs.open(csv_path, std::ios::in);
    if(!csv_ifs.is_open()) throw std::runtime_error("Could not open file");

    csv_ifs.ignore(numeric_limits<streamsize>::max(), '\n'); // Get rid of the first line

    int i = 0;
    while(true) {
        if(!getline(csv_ifs, line)) break;
        istringstream ss(line);
        std::vector<std::string> line_contents;
        while (ss) {
            string s;
            if (!getline(ss, s, ',')) break;
            line_contents.push_back(s);
        }
        pcl::PointXYZ center = pcl::PointXYZ(stof(line_contents[1]), stof(line_contents[2]), stof(line_contents[3]));
        csv.centers.push_back(center);
        csv.labels.push_back(line_contents[4].substr(0, line_contents[4].size() - 1));
        i++;
    }

    csv_ifs.close();
}

Dataset::Dataset(const string &scene_name) {
    active_scene = scene_name;
    std::string csv_folder_path = out_dir + "/" + scene_name + "/";
    std::vector<std::string> fnames;
    list_files(csv_folder_path, fnames);
    load_label_from_csv(csv_folder_path + fnames[0] + ".csv");
}

void Dataset::load_landmarks(int landmark_index) {
    std::string index = std::to_string(landmark_index);

    if(just_save_files) {
        lasp_path_2016 = out_dir + "/" + active_scene + "/2016/" + (active_scene + "_" + index + ".las") ;
        load_las_file(lasp_path_2016, xyz_rgb_2016);
        lasp_path_2020 = out_dir + "/" + active_scene + "/2020/" + (active_scene + "_" + index + ".las") ;
        load_las_file(lasp_path_2020, xyz_rgb_2020);
    }
    else {
        lasp_path_2016 = out_dir + "/" + active_scene + "/2016/" + (active_scene + "_" + index + "_original_clustered.ply");
        load_ply_file(lasp_path_2016, xyz_rgb_2016);
        lasp_path_2020 = out_dir + "/" + active_scene + "/2020/" + (active_scene + "_" + index + "_original_clustered.ply");
        load_ply_file(lasp_path_2020, xyz_rgb_2020);
    }
    active_landmark = landmark_index;
}
