//
// Created by andreas on 17/11/20.
//
#ifndef INC_3D_OBJECT_DETECTION_DATASET_H
#define INC_3D_OBJECT_DETECTION_DATASET_H
#include<vector>
#include<string>
#include <iostream>
#include <iterator>
#include <fstream>
#include <algorithm>
#include <boost/filesystem.hpp>
#include <boost/shared_ptr.hpp>

#include <pcl/point_types.h>
#include <pcl/point_cloud.h>

//#include <opencv2/core.hpp>
//#include <opencv2/imgcodecs.hpp>
//#include <opencv2/highgui/highgui.hpp>
#include <eigen3/Eigen/Core>
//#include "DataStructure.h"


#include <liblas/liblas.hpp>
#include <fstream>  // std::ifstream
#include <iostream> // std::cout


typedef pcl::PointXYZRGB Point3D;
typedef pcl::PointCloud<Point3D> PointCloud3D;

class Dataset
{

public:
    static std::string out_dir;
    static bool just_save_files;

    struct csv_file{
        std::vector<std::string> labels;
        std::vector<pcl::PointXYZ> centers;
    }csv;

    explicit Dataset(const std::string& scene_name);
    void load_landmarks(int landmark_index);


    std::string active_scene; //The scene name currently loaded
    int active_landmark; //the current index of the landmark within the scene
    PointCloud3D::Ptr xyz_rgb_2016;
    PointCloud3D::Ptr xyz_rgb_2020;
private:
    void load_las_file(const std::string& las_path, PointCloud3D::Ptr& out_pcl);
    void load_ply_file(const std::string& las_path, PointCloud3D::Ptr& out_pcl);
    void load_label_from_csv(std::string csv_path);

    std::string lasp_path_2016;
    std::string lasp_path_2020;
};



#endif //INC_3D_OBJECT_DETECTION_DATASET_H
