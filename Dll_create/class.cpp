#include "pch.h"
#include "class.h"



testCpp::testCpp() {

	member = new std::string("abc");
}

testCpp::~testCpp(){
	delete this->member;

}

int testCpp::add_member_size(int x) {

	return x + this->member->size();
}