#pragma once
#include <string>


class testCpp
{
public:
	testCpp();
	~testCpp();

	int add_member_size(int x);

private:
	std::string* member;
};



extern "C" __declspec(dllexport) unsigned int obj_call(int x)
{
	testCpp obj;
	return obj.add_member_size(x);
}
