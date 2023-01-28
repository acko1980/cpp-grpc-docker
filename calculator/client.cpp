#include <stdexcept>
#include <iostream>
#include <memory>
#include <string>
#include <cmath>

#include <grpcpp/grpcpp.h>

#include "calculator_service.grpc.pb.h"

using grpc::Channel;
using grpc::ClientContext;
using grpc::Status;

using ::calculator::proto::Calculator;
using ::calculator::proto::ComputeRequest;
using ::calculator::proto::ComputeResponse;

class CalculatorClient {

 public:

  CalculatorClient(std::shared_ptr<Channel> channel)
      : stub_(Calculator::NewStub(channel)) {}

  // Assembles the client's payload, sends it and presents the response back
  // from the server.

  double call_calculate(double lhs, const std::string& op, double rhs) {

    calculator::proto::Operator e_operator;

    if (op == "ADD") e_operator = calculator::proto::ADD;
    else if (op == "SUB") e_operator = calculator::proto::SUB;
    else if (op == "MUL") e_operator = calculator::proto::MUL;
    else if (op == "DIV") e_operator = calculator::proto::DIV;
    else if (op == "POW") e_operator = calculator::proto::POW;
    else throw std::runtime_error("Invalid operator " + op + ".\n");

    // Data we are sending to the server.
    ::calculator::proto::ComputeRequest request;

    request.set_lhs(lhs);
    request.set_operator_(e_operator);
    request.set_rhs(rhs);

    // Container for the data we expect from the server.
    ::calculator::proto::ComputeResponse reply;

    // Context for the client. It could be used to convey extra information to
    // the server and/or tweak certain RPC behaviors.
    ClientContext context;

    // The actual RPC.
    Status status = stub_->Compute(&context, request, &reply);

    // Act upon its status.
    if (status.ok()) {
      return reply.result();

    }
    else {
      std::cout << status.error_code() << ": " << status.error_message() << std::endl;
      return std::nan("nan");
    }

  }

 private:
  std::unique_ptr<Calculator::Stub> stub_;

};

int main(int argc, char** argv) {

  // Instantiate the client. It requires a channel, out of which the actual RPCs
  // are created. This channel models a connection to an endpoint specified by
  // the argument "--target=" which is the only expected argument.
  // We indicate that the channel isn't authenticated (use of
  // InsecureChannelCredentials()).

  std::string target_str;
  std::string arg_str("--target");

  if (argc > 1) {

    std::string arg_val = argv[1];
    size_t start_pos = arg_val.find(arg_str);

    if (start_pos != std::string::npos) {

      start_pos += arg_str.size();

      if (arg_val[start_pos] == '=') {
        target_str = arg_val.substr(start_pos + 1);
      }
      else {
        std::cout << "The only correct argument syntax is --target=" << std::endl;
        return 0;
      }

    }
    else {
      std::cout << "The only acceptable argument is --target=" << std::endl;
      return 0;
    }

  }

  else {
    target_str = "localhost:50051";
  }

  CalculatorClient client(grpc::CreateChannel(target_str, grpc::InsecureChannelCredentials()));

  // Example call.
  double reply = client.call_calculate(2., "MUL", 5.);

  std::cout << "Calculator response received: " << reply << std::endl;

  return 0;

}
