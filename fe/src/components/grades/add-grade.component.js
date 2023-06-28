import React, { Component } from "react";
import GradeDataService from "../../services/grade.service";

export default class AddGrade extends Component {
  constructor(props) {
    super(props);
    this.onChangeTitle = this.onChangeTitle.bind(this);
    this.onChangeDescription = this.onChangeDescription.bind(this);
    this.saveGrade = this.saveGrade.bind(this);
    this.newGrade = this.newGrade.bind(this);

    this.state = {
      id: null,
      title: "",
      descr: "", 
      published: false
    };
  }

  onChangeTitle(e) {
    this.setState({
      title: e.target.value
    });
  }

  onChangeDescription(e) {
    this.setState({
      descr: e.target.value
    });
  }

  saveGrade() {
    var data = {
      title: this.state.title,
      descr: this.state.descr
    };

    GradeDataService.create(data)
      .then(response => {
        this.setState({
          id: response.data.id,
          title: response.data.title,
          descr: response.data.descr,
          published: response.data.published,

          submitted: true
        });
        console.log(response.data);
      })
      .catch(e => {
        console.log(e);
      });
  }

  newGrade() {
    this.setState({
      id: null,
      title: "",
      descr: ""
    });
  }

  render() {
    return (
      <div className="submit-form">
        {this.state.submitted ? (
          <div>
            <h4>You submitted successfully!</h4>
            <button className="btn btn-success" onClick={this.newGrade}>
              Add
            </button>
          </div>
        ) : (
          <div>
            <div className="form-group">
              <label htmlFor="title">Title</label>
              <input
                type="text"
                className="form-control"
                id="title"
                required
                value={this.state.title}
                onChange={this.onChangeTitle}
                name="title"
              />
            </div>

            <div className="form-group">
              <label htmlFor="descr">Description</label>
              <input
                type="text"
                className="form-control"
                id="descr"
                required
                value={this.state.descr}
                onChange={this.onChangeDescription}
                name="descr"
              />
            </div>

            <button onClick={this.saveGrade} className="btn btn-success">
              Submit
            </button>
          </div>
        )}
      </div>
    );
  }
}
