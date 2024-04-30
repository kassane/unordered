/* Copyright 2024 Joaquin M Lopez Munoz.
 * Distributed under the Boost Software License, Version 1.0.
 * (See accompanying file LICENSE_1_0.txt or copy at
 * http://www.boost.org/LICENSE_1_0.txt)
 *
 * See https://www.boost.org/libs/unordered for library home page.
 */

#ifndef BOOST_UNORDERED_DETAIL_CUMULATIVE_STATS_HPP
#define BOOST_UNORDERED_DETAIL_CUMULATIVE_STATS_HPP

#include <array>
#include <boost/config.hpp>
#include <boost/mp11/tuple.hpp>
#include <cmath>
#include <cstddef>

#if defined(BOOST_HAS_THREADS)
#include <mutex>
#endif

namespace boost{
namespace unordered{
namespace detail{

/* Cumulative one-pass calculation of the average, variance and deviation of
 * running sequences.
 */

struct cumulative_stats_summary
{
  double average;
  double variance;
  double deviation;
};

struct cumulative_stats_data
{
  double m=0.0;
  double m_prior=0.0;
  double s=0.0;
};

struct welfords_algorithm /* 0-based */
{
  template<typename T>
  int operator()(T&& x,cumulative_stats_data& d)const noexcept
  {
    static_assert(
      noexcept(static_cast<double>(x)),
      "Argument conversion to double must not throw.");

    d.m_prior=d.m;
    d.m+=(static_cast<double>(x)-d.m)/static_cast<double>(n);
    d.s+=(n!=1)*
      (static_cast<double>(x)-d.m_prior)*(static_cast<double>(x)-d.m);

    return 0; /* mp11::tuple_transform requires that return type not be void */
  }

  std::size_t n;
};

/* Stats calculated jointly for N same-sized sequences to save the space
 * for n.
 */

template<std::size_t N>
class cumulative_stats
{
public:
  void reset()noexcept{*this=cumulative_stats();}
  
  template<typename... Ts>
  void add(Ts&&... xs)noexcept
  {
    static_assert(
      sizeof...(Ts)==N,"A sample must be provided for each sequence.");

    if(BOOST_UNLIKELY(++n==0)){ /* wraparound */
      reset();
      n=1;
    }
    mp11::tuple_transform(
      welfords_algorithm{n},
      std::forward_as_tuple(std::forward<Ts>(xs)...),
      data);
  }
  
  template<std::size_t I>
  cumulative_stats_summary get_summary()const noexcept
  {
    double average=data[I].m,
           variance=n!=0?data[I].s/static_cast<double>(n):0.0, /* biased */
           deviation=std::sqrt(variance);
    return {average,variance,deviation};
  }

private:
  std::size_t                         n=0;
  std::array<cumulative_stats_data,N> data;
};

#if defined(BOOST_HAS_THREADS)

template<std::size_t N>
class concurrent_cumulative_stats:cumulative_stats<N>
{
  using super=cumulative_stats<N>;
  using lock_guard=std::lock_guard<std::mutex>;

public:
  concurrent_cumulative_stats()noexcept:super{}{}
  concurrent_cumulative_stats(const concurrent_cumulative_stats& x)noexcept:
    concurrent_cumulative_stats{x,lock_guard{x.mut}}{}

  concurrent_cumulative_stats&
  operator=(const concurrent_cumulative_stats& x)noexcept
  {
    auto x1=x;
    lock_guard lck{mut};
    static_cast<super&>(*this)=x1;
    return *this;
  }

  void reset()noexcept
  {
    lock_guard lck{mut};
    super::reset();
  }
  
  template<typename... Ts>
  void add(Ts&&... xs)noexcept
  {
    lock_guard lck{mut};
    super::add(std::forward<Ts>(xs)...);
  }
  
  template<std::size_t I>
  cumulative_stats_summary get_summary()const noexcept
  {
    lock_guard lck{mut};
    return super::template get_summary<I>();
  }

private:
  concurrent_cumulative_stats(const super& x,lock_guard&&):super{x}{}

  mutable std::mutex mut;
};

#else

template<std::size_t N>
using concurrent_cumulative_stats=cumulative_stats<N>;

#endif

} /* namespace detail */
} /* namespace unordered */
} /* namespace boost */

#endif
